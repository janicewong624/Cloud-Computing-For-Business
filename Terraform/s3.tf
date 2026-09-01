# assignment-s3-uploads: holds room/equipment/book photo uploads and app
# release artifacts. Bucket ACLs stay blocked; only unauthenticated
# GetObject under uploads/* is allowed via bucket policy so images render in
# the browser, without allowing public listing or writes.
resource "aws_s3_bucket" "uploads" {
  # Suffix the account ID so the globally-unique bucket name doesn't collide
  # with another account's, e.g. assignment-s3-uploads-123456789012.
  bucket = "${var.s3_bucket_name}-${data.aws_caller_identity.current.account_id}"

  # Sandbox environment: by the time you `terraform destroy`, this bucket
  # will contain uploaded photos and the app release zip. AWS refuses to
  # delete a non-empty bucket, so without force_destroy the destroy fails.
  force_destroy = true

  tags = {
    Name = "${var.name_prefix}-s3-uploads"
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.uploads.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadUploadedPhotos"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.uploads.arn}/uploads/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.uploads]
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}