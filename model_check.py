import sys
import os
from transformers import DonutProcessor, VisionEncoderDecoderModel

MODEL_DIR = "./model"

print(f"🔍 Validating model in {MODEL_DIR}...")

# 1. Check if the folder exists
if not os.path.exists(MODEL_DIR):
    print(f"❌ Error: Directory {MODEL_DIR} does not exist.")
    sys.exit(1)

# 2. Check for key files presence
required_files = ["config.json", "pytorch_model.bin", "tokenizer.json", "preprocessor_config.json"]
# Note: pytorch_model.bin might be also model.safetensors
files_in_dir = os.listdir(MODEL_DIR)
print(f"📂 Files found: {files_in_dir}")

# 3. Attempt to load the model (The real corruption test)
try:
    print("⏳ Attempting to load Processor...")
    processor = DonutProcessor.from_pretrained(MODEL_DIR)

    print("⏳ Attempting to load Model...")
    model = VisionEncoderDecoderModel.from_pretrained(MODEL_DIR)

    print("✅ SUCCESS: Model is valid and loadable.")
    sys.exit(0)

except Exception as e:
    print(f"❌ CRITICAL FAILURE: Model is corrupt or incompatible.")
    print(f"Error details: {e}")
    sys.exit(1)