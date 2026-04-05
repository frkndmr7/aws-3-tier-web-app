variable "project_name" {
  description = "Projenin adı (Örn: web-3tier-app)"
  type        = string
}

variable "environment" {
  description = "Çalışma ortamı (dev, prod, poc)"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "CloudFront'un bağlanacağı S3 bucket'ın domain adresi"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID (Bağımlılık yönetimi için)"
  type        = string
}

variable "s3_bucket_arn" {
  type = string
}