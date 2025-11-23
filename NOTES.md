
### Manual pushing a docker image into ECR repo:    

    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_URL