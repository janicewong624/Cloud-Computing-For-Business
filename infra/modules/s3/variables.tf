variable "name_prefix" {
  description = "Prefix applied to all resource names in this module."
  type        = string
  default     = "assignment"
}

variable "bucket_name" {
  description = "Name of the S3 bucket you created manually via the console (see infra/README.md). Must match exactly - Terraform never creates or reads this bucket, only builds its ARN/domain name as strings from this value."
  type        = string
}

variable "aws_region" {
  description = "AWS region, used only to build the bucket's regional domain name as a string."
  type        = string
  default     = "us-east-1"
}

variable "public_read_prefix" {
  description = "Object key prefix (glob) that should be publicly readable, e.g. uploads/*. Informational only now - the actual bucket policy is set manually (see infra/README.md), not by Terraform."
  type        = string
  default     = "uploads/*"
}
