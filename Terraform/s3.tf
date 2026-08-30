resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "photos" {
  bucket = "library-photos-${random_id.bucket_suffix.hex}"
  tags   = { Name = "library-photos" }
}

resource "aws_s3_bucket_public_access_block" "photos" {
  bucket = aws_s3_bucket.photos.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Photos need to be viewable by anyone visiting the site (they're rendered
# in plain <img> tags), so allow public read on objects only - not full
# bucket listing, and never write access.
resource "aws_s3_bucket_policy" "photos_public_read" {
  bucket = aws_s3_bucket.photos.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.photos.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.photos]
}