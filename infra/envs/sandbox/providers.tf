terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Pinned to the last v4 release on purpose, NOT "~> 5.0". Academy Lab
    # accounts have an org-level SCP that explicitly denies
    # s3:GetBucketObjectLockConfiguration. The v5 aws_s3_bucket resource
    # always calls that API when reading a bucket back after create/refresh
    # and hard-fails on AccessDenied; the v4 resource never makes that call,
    # so this version avoids the problem entirely instead of working around
    # a permission we can't grant ourselves.
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
