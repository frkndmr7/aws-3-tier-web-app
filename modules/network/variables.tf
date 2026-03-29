variable "project_name" {
  type    = string
  default = "3tier-app"
}

variable "environment" {
  type    = string
  default = "poc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Subnetler için liste kullanmak işimizi çok kolaylaştırır
variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}