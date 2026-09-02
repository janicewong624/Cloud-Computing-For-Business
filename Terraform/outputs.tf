output "alb_dns_name" {
  description = "Visit this URL in your browser - it's the ONLY way you should access the site"
  value       = "http://${aws_lb.main.dns_name}"
}

output "rds_endpoint" {
  description = "RDS endpoint (private - only reachable from inside the VPC, e.g. from an EC2 instance)"
  value       = aws_db_instance.main.address
}

output "s3_bucket_name" {
  value = aws_s3_bucket.uploads.bucket
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
