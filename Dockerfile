FROM python:3.11-slim

# Set environment variables to prevent Python from buffering stdout/stderr
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# At the moment we deploy in AWS Fargate (and so have no GPU). Later we'll migrate to ECS on EC2 with GPU.
# Install PyTorch CPU specifically to prevent downlaod of massive GPU libs (~200MB instead of ~3GB)
RUN pip install --no-cache-dir torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cpu

# Install the rest of the requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

COPY ./model /app/model
ENV MODEL_PATH=/app/model

EXPOSE 8080

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]