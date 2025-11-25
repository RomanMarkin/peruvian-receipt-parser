provider "aws" {
  profile = var.aws_profile
  region = var.aws_region
}

# Get created ECR repo
data "aws_ecr_repository" "repo" {
  name = "${var.project_name}-repo"
}

# Get Account ID
data "aws_caller_identity" "current" {}

# Call the module
module "production" {
  source = "../../modules/app_infra"
  environment        = "production"
  project_name       = var.project_name
  aws_region         = var.aws_region
  account_id         = data.aws_caller_identity.current.account_id
  vpc_cidr           = var.vpc_cidr
  instance_count     = var.instance_count
  ecr_repository_url = data.aws_ecr_repository.repo.repository_url
}