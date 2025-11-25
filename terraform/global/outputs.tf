output "ecr_repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.repo.name
}

output "ecr_repository_url" {
  description = "The full URL of the ECR repository"
  value       = aws_ecr_repository.repo.repository_url
}