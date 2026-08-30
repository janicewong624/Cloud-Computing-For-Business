terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# AWS Academy Learner Lab issues temporary credentials (Access Key, Secret
# Key, Session Token) that expire every few hours. Rather than hardcoding
# them here, export them as environment variables before running terraform:
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
#   export AWS_SESSION_TOKEN=...
# Terraform's AWS provider picks these up automatically - nothing to
# configure below for credentials.
provider "aws" {
  region = var.aws_region
}
