output "ecr_repo_url" {
  value = aws_ecr_repository.repo.repository_url
}

output "api_url" {
  value = "http://${aws_lb.main.dns_name}/docs"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.receipts.bucket
}