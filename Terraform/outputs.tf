output "alb_dns_name" {
  description = "Public URL to reach the app through (http://<this>)."
  value       = aws_lb.web.dns_name
}

output "app_internal_alb_dns_name" {
  description = "Internal ALB DNS name in front of the App tier (reference only - not reachable from outside the VPC)."
  value       = aws_lb.app.dns_name
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "rds_endpoint" {
  value     = aws_db_instance.this.endpoint
  sensitive = true
}

output "s3_bucket_name" {
  value = aws_s3_bucket.uploads.id
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "web_asg_name" {
  value = aws_autoscaling_group.web.name
}

output "app_asg_name" {
  value = aws_autoscaling_group.app.name
}