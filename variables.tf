variable "db_password" {
  type        = string
  description = "Database password from tfvars"
  sensitive   = true # Senior Dokunuşu: Şifrenin terminal çıktılarında görünmesini engeller
}