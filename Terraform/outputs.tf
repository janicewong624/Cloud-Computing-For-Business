output "website_url" {
  description = "Open this in your browser to test the site"
  value       = "http://${aws_lb.external.dns_name}"
}

output "external_alb_dns" {
  value = aws_lb.external.dns_name
}

output "internal_alb_dns" {
  value = aws_lb.internal.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "s3_bucket_name" {
  value = aws_s3_bucket.photos.bucket
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}