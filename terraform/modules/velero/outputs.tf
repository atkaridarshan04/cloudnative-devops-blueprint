output "bucket_name" {
  value = aws_s3_bucket.backups.bucket
}

output "role_arn" {
  value = module.irsa.role_arn
}
