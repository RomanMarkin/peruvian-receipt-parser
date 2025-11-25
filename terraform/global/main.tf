provider "aws" {
  profile = var.aws_profile
  region = var.aws_region
}

# ECR repo to store project's Docker images
resource "aws_ecr_repository" "repo" {
  name = "${var.project_name}-repo"
  force_delete = true
}