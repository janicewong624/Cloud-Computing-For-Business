# ---------------------------------------------------------------------------
# The S3 bucket itself is NOT managed - or even read - by Terraform, on
# purpose. AWS Academy Learner Lab accounts have an org-level Service
# Control Policy that explicitly denies s3:GetBucketObjectLockConfiguration.
# Both the aws_s3_bucket resource AND the aws_s3_bucket data source call
# that API as part of their normal read, and hard-fail on the AccessDenied
# every single time - not just once, and there is no permission we can
# grant ourselves to fix it (it's an explicit Deny at the AWS Organizations
# level, above IAM). So this module makes zero AWS API calls for the
# bucket: the ARN and regional domain name below are just string formulas,
# not looked up. The bucket itself is created once, manually, outside
# Terraform (see infra/README.md "One-time manual S3 bucket setup").
# ---------------------------------------------------------------------------

locals {
  bucket_arn                  = "arn:aws:s3:::${var.bucket_name}"
  bucket_regional_domain_name = "${var.bucket_name}.s3.${var.aws_region}.amazonaws.com"
}
