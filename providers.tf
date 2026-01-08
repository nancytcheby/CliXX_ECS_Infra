# ----------------------------------------
# Terraform Configuration
# ----------------------------------------

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ----------------------------------------
# AWS Provider - Deploy to Dev Account
# ----------------------------------------

provider "aws" {
  region = var.aws_region
}

# Provider for dev account Route53
provider "aws" {
  alias  = "dev_account"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::083587468058:role/Route53CrossAccountRole"
  }
}