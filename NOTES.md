
### Manual model download (for dev):
 
    hf download RomanMarkin/peruvian-receipts-donut-v1 \
        --local-dir ./model \
        --exclude "*.git*" "README.md"

### Manual model validation (for dev):

    ./modley_check.py

### Manual build container (for dev)
 
    docker build -t peruvian-receipt-parser .
    docker run --name peruvian-receipt-parser \
        -p 8080:8080 \
        -v ~/.aws:/root/.aws \
        -e AWS_PROFILE=donat-deploy \
        peruvian-receipt-parser

### Manual pushing a docker image into ECR repo:    

    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_URL