variable "aws_profile" {
  description = "AWS CLI profile to use for deployment"
  type        = string
  default     = "donat-deploy"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "receipt-parser"
}

variable "bucket_name" {
  default = "receipts-storage-secure-8823"
}