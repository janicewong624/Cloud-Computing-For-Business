output "bucket_id" {
  value = var.bucket_name
}

output "bucket_arn" {
  value = local.bucket_arn
}

output "bucket_regional_domain_name" {
  value = local.bucket_regional_domain_name
}
