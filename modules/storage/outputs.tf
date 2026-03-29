output "db_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.media_bucket.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.media_bucket.arn
}

output "efs_id" {
  value = aws_efs_file_system.wp_shared_files.id
}

