variable "project_name" {}
variable "environment" {}
variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}
variable "db_sg_id" {}

variable "db_name" {
  default = "wordpressdb"
}

variable "db_user" {
  default = "admin"
}

# Junior Notu: Normalde şifre buraya yazılmaz (Secret Manager kullanılır) 
# ama POC için şimdilik basit tutuyoruz.
variable "db_password" {
  description = "RDS şifresi"
  type        = string
  # default kısmını sildik, Terraform artık bunu bize soracak
}


