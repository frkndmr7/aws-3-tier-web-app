variable "db_password" {
  type        = string
  description = "Database password from tfvars"
  sensitive   = true # Senior Dokunuşu: Şifrenin terminal çıktılarında görünmesini engeller
}

variable "project_name" {
  description = "Projenin genel adı"
  type        = string
  default     = "web-3tier-app" # Senin proje adın neyse o
}

variable "environment" {
  description = "Çalışma ortamı"
  type        = string
  default     = "poc"
}

# Diğer değişkenlerin (aws_region, db_user vb.) zaten burada olmalı