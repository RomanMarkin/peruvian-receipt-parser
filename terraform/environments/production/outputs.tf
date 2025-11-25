# --- Outputs for app usage ---
output "api_base_url" {
  description = "The public URL of the Load Balancer"
  value       = "http://${module.production.api_base_url}"
}

output "api_docs_url" {
  description = "App documentation URL"
  value       = "http://${module.production.api_docs_url}/docs"
}

output "s3_bucket_name" {
  description = "The name of the bucket where receipts are stored"
  value       = module.production.s3_bucket_name
}

# --- Outputs for GitHub Actions CI/CD ---
output "aws_region" {
  description = "The AWS Region to configure in GitHub Actions"
  value       = var.aws_region
}

output "ecs_service_name" {
  description = "The name of the ECS Service"
  value       = module.production.ecs_service_name
}

output "ecs_cluster_name" {
  description = "The name of the ECS Cluster"
  value       = module.production.ecs_cluster_name
}

output "ecs_task_definition_family" {
  description = "The Family Name of the Task Definition"
  value       = module.production.ecs_task_definition_family
}

output "container_name" {
  description = "The name of the container defined in the Task Definition"
  value       = module.production.container_name
}

output "cloudwatch_log_group" {
  description = "Where to find the logs in AWS Console"
  value       = module.production.cloudwatch_log_group
}