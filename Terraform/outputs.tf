output "alb_dns_name" {
  value       = aws_lb.external_alb.dns_name
  description = "Access URL via ALB"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.images.bucket
  description = "Created S3 Bucket Name"
}

output "rds_endpoint" {
  value       = aws_db_instance.rds.endpoint
  description = "RDS Connection Endpoint"
}