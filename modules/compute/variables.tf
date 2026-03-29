variable "project_name" {}
variable "environment" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" {}
variable "ecs_sg_id" {}
variable "execution_role_arn" {}
variable "task_role_arn" {}
variable "db_endpoint" {}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
variable "s3_bucket_name" {}
variable "efs_id" {}

variable "aws_region" {
  default = "us-east-1" # Eğer us-east-1'de kalacaksan böyle kalsın
}