terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # State bucket + lock table must be bootstrapped manually ONCE before this
  # backend can be used - Terraform can't create the backend it's about to
  # store its own state in:
  #
  #   aws s3api create-bucket --bucket assignment-tfstate-<your-account-id> --region us-east-1
  #   aws s3api put-bucket-versioning --bucket assignment-tfstate-<your-account-id> \
  #     --versioning-configuration Status=Enabled
  #   aws dynamodb create-table --table-name assignment-tf-lock \
  #     --attribute-definitions AttributeName=LockID,AttributeType=S \
  #     --key-schema AttributeName=LockID,KeyType=HASH \
  #     --billing-mode PAY_PER_REQUEST
  #
  # S3 bucket names are GLOBALLY unique - replace the bucket name below with
  # your own (e.g. assignment-tfstate-<your-account-id>, find it with
  # `aws sts get-caller-identity`) and create it with that exact name first.
  backend "s3" {
    bucket         = "assignment-tfstate-219533466732" # <-- change this
    key            = "sandbox/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "assignment-tf-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}