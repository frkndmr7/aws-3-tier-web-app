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

output "s3_bucket_domain_name" {
  description = "CloudFront'un bağlanacağı S3 adresi"
  # Senin resource ismin 'media_bucket' olduğu için böyle yazıyoruz:
  value       = aws_s3_bucket.media_bucket.bucket_regional_domain_name
  # value       = aws_s3_bucket.media_bucket.bucket_domain_name
  # value = "${aws_s3_bucket.media_bucket.id}.s3.amazonaws.com"
}

output "s3_bucket_id" {
  description = "S3 Bucket ID"
  value       = aws_s3_bucket.media_bucket.id
}


