


# 2. WordPress paneline girmem gerekecek olan CloudFront URL'i
output "cloudfront_domain_name" {
  description = "CloudFront dağıtımının domain adresi (Örn: d123.cloudfront.net)"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}