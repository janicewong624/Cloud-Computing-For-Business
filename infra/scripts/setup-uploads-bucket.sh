#!/bin/bash
# Run this ONCE, manually, from CloudShell (or any shell with AWS CLI +
# credentials) after creating the uploads bucket via the console. Terraform
# does not manage this bucket at all (see infra/modules/s3/main.tf for why),
# so its public-read policy, public access block, and CORS settings have to
# be applied this way instead of via `terraform apply`.
#
# Usage: ./setup-uploads-bucket.sh assignment-s3-uploads-<your-account-id>
set -euo pipefail

BUCKET="$1"
REGION="${2:-us-east-1}"

echo "Configuring public access block (allow a bucket policy, block ACLs)..."
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false \
  --region "$REGION"

echo "Applying public-read bucket policy for uploads/* ..."
cat > /tmp/bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadUploads",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${BUCKET}/uploads/*"
    }
  ]
}
EOF
aws s3api put-bucket-policy --bucket "$BUCKET" --policy file:///tmp/bucket-policy.json --region "$REGION"

echo "Applying CORS configuration..."
cat > /tmp/cors.json <<EOF
{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET"],
      "AllowedOrigins": ["*"],
      "MaxAgeSeconds": 3000
    }
  ]
}
EOF
aws s3api put-bucket-cors --bucket "$BUCKET" --cors-configuration file:///tmp/cors.json --region "$REGION"

echo "Done. Bucket $BUCKET is now configured for public-read uploads."
