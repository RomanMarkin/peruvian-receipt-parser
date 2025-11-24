import os
import re
from contextlib import asynccontextmanager
from io import BytesIO

import boto3
import torch
from PIL import Image
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import DonutProcessor, VisionEncoderDecoderModel

# --- Configuration ---
MODEL_PATH = os.getenv("MODEL_PATH", "./model")
DEVICE = "cuda" if torch.cuda.is_available() else "mps" if torch.backends.mps.is_available() else "cpu"

# --- Global State ---
ml_models = {}
s3_client = boto3.client('s3')


# --- Lifespan Manager ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Load the model BEFORE the app starts.
    Clean it up AFTER the app stops.
    """
    print(f"Loading model from {MODEL_PATH} on {DEVICE}...")
    try:
        # Load model into the global dictionary
        processor = DonutProcessor.from_pretrained(MODEL_PATH)
        model = VisionEncoderDecoderModel.from_pretrained(MODEL_PATH)
        model.to(DEVICE)
        model.eval()

        ml_models["processor"] = processor
        ml_models["model"] = model
        print("✅ Model loaded successfully.")
        yield
        # Clean up resources on shutdown
        ml_models.clear()
        print("🛑 Model unloaded.")
    except Exception as e:
        print(f"❌ CRITICAL: Failed to load model: {e}")
        # We raise the error to prevent the app from starting broken
        raise e


# Initialize App with Lifespan
app = FastAPI(title="Peruvian Receipt Parser", lifespan=lifespan)


class ReceiptRequest(BaseModel):
    s3_url: str


def parse_s3_url(url: str):
    if not url.startswith("s3://"):
        raise ValueError("URL must start with s3://")
    path = url[5:]
    parts = path.split("/", 1)
    if len(parts) != 2:
        raise ValueError("Invalid S3 URL format")
    return parts[0], parts[1]


@app.post("/parse_receipt")
async def parse_receipt(request: ReceiptRequest):
    # Access the model from the global dictionary
    model = ml_models.get("model")
    processor = ml_models.get("processor")

    if not model or not processor:
        raise HTTPException(status_code=500, detail="Model is not loaded.")

    # 1. Fetch Image
    try:
        bucket_name, key = parse_s3_url(request.s3_url)
        response = s3_client.get_object(Bucket=bucket_name, Key=key)
        image_data = response['Body'].read()
        image = Image.open(BytesIO(image_data)).convert("RGB")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error fetching image from S3: {str(e)}")

    # 2. Preprocess
    try:
        pixel_values = processor(image, return_tensors="pt").pixel_values
        pixel_values = pixel_values.to(DEVICE)

        task_prompt = "<s_receipt>"
        decoder_input_ids = processor.tokenizer(task_prompt, add_special_tokens=False, return_tensors="pt").input_ids
        decoder_input_ids = decoder_input_ids.to(DEVICE)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Preprocessing failed: {str(e)}")

    # 3. Inference
    try:
        outputs = model.generate(
            pixel_values,
            decoder_input_ids=decoder_input_ids,
            max_length=model.decoder.config.max_position_embeddings,
            early_stopping=True,
            pad_token_id=processor.tokenizer.pad_token_id,
            eos_token_id=processor.tokenizer.eos_token_id,
            use_cache=True,
            num_beams=1,
            bad_words_ids=[[processor.tokenizer.unk_token_id]],
            return_dict_in_generate=True,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference failed: {str(e)}")

    # 4. Post-process
    try:
        sequence = processor.batch_decode(outputs.sequences)[0]
        sequence = sequence.replace(processor.tokenizer.eos_token, "").replace(processor.tokenizer.pad_token, "")
        sequence = re.sub(r"<.*?>", "", sequence, count=1).strip()

        json_output = processor.token2json(sequence)

        target_fields = ["issuer_ruc", "document_series", "document_number", "issue_date", "total"]
        filtered_output = {k: json_output.get(k, None) for k in target_fields}

        return filtered_output

    except Exception as e:
        return {"error": "JSON parsing failed", "raw_sequence": sequence}


if __name__ == "__main__":
    import uvicorn
    # This runs the server when you execute the script directly
    uvicorn.run(app, host="0.0.0.0", port=8000)