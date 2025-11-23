import os
import sys
from transformers import DonutProcessor, VisionEncoderDecoderModel

# Defined in Dockerfile, or defaults to the local path
MODEL_PATH = os.getenv("MODEL_PATH", "/app/model")

print(f"--- STARTING MODEL SANITY CHECK ---")
print(f"Checking model at: {MODEL_PATH}")

try:
    # 1. Check if directory exists
    if not os.path.exists(MODEL_PATH):
        print(f"ERROR: Model directory not found at {MODEL_PATH}")
        sys.exit(1)

    # 2. Check for critical files
    required_files = ["config.json", "tokenizer.json", "special_tokens_map.json"]
    files_in_dir = os.listdir(MODEL_PATH)
    missing_files = [f for f in required_files if f not in files_in_dir]

    if missing_files:
        print(f"ERROR: Missing critical model files: {missing_files}")
        print(f"Found: {files_in_dir}")
        sys.exit(1)

    # 3. Attempt to load the model into memory
    print("Attempting to load Processor...")
    processor = DonutProcessor.from_pretrained(MODEL_PATH)

    print("Attempting to load Model...")
    model = VisionEncoderDecoderModel.from_pretrained(MODEL_PATH)

    print("SUCCESS: Model loaded correctly.")
    sys.exit(0)

except Exception as e:
    print(f"CRITICAL FAILURE during sanity check: {e}")
    sys.exit(1)