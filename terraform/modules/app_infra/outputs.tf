# --- Outputs for app usage ---
output "api_base_url" {
  description = "The public URL of the Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "api_docs_url" {
  description = "App documentation URL"
  value       = "http://${aws_lb.main.dns_name}/docs"
}

output "s3_bucket_name" {
  description = "The name of the bucket where receipts are stored"
  value       = aws_s3_bucket.receipts.bucket
}

# --- Outputs for GitHub Actions CI/CD ---
output "aws_region" {
  description = "The AWS Region to configure in GitHub Actions"
  value       = var.aws_region
}

output "ecs_service_name" {
  description = "The name of the ECS Service"
  value       = aws_ecs_service.main.name
}

output "ecs_cluster_name" {
  description = "The name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_task_definition_family" {
  description = "The Family Name of the Task Definition"
  value       = aws_ecs_task_definition.app.family
}

output "container_name" {
  description = "The name of the container defined in the Task Definition"
  value       = "app" # This matches the 'name' inside 'container_definitions' in main.tf
}

output "cloudwatch_log_group" {
  description = "Where to find the logs in AWS Console"
  value       = aws_cloudwatch_log_group.logs.name
}