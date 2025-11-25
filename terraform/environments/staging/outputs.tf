# --- Outputs for app usage ---
output "api_base_url" {
  description = "The public URL of the Load Balancer"
  value       = module.staging.api_base_url
}

output "api_docs_url" {
  description = "App documentation URL"
  value       = module.staging.api_docs_url
}

output "s3_bucket_name" {
  description = "The name of the bucket where receipts are stored"
  value       = module.staging.s3_bucket_name
}

# --- Outputs for GitHub Actions CI/CD ---
output "aws_region" {
  description = "The AWS Region to configure in GitHub Actions"
  value       = var.aws_region
}

output "ecs_service_name" {
  description = "The name of the ECS Service"
  value       = module.staging.ecs_service_name
}

output "ecs_cluster_name" {
  description = "The name of the ECS Cluster"
  value       = module.staging.ecs_cluster_name
}

output "ecs_task_definition_family" {
  description = "The Family Name of the Task Definition"
  value       = module.staging.ecs_task_definition_family
}

output "container_name" {
  description = "The name of the container defined in the Task Definition"
  value       = module.staging.container_name
}

output "cloudwatch_log_group" {
  description = "Where to find the logs in AWS Console"
  value       = module.staging.cloudwatch_log_group
}