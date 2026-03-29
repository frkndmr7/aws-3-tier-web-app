module "network" {
  source       = "./modules/network"
  project_name = "web-3tier-app"
  environment  = "poc"
}

# Mevcut network modülünün altına ekle
module "storage" {
  source            = "./modules/storage"
  project_name      = "web-3tier-app"
  environment       = "poc"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  db_sg_id          = module.network.db_sg_id
  db_password       = var.db_password
}

# Storage modülünün altına ekle
module "iam" {
  source        = "./modules/iam"
  project_name  = "web-3tier-app"
  environment   = "poc"
  s3_bucket_arn = module.storage.s3_bucket_arn # Storage'dan gelen bilgi!
}

module "cicd" {
  source       = "./modules/cicd"
  project_name = "web-3tier-app"
}

module "compute" {
  source             = "./modules/compute"
  aws_region = "us-east-1"
  project_name       = "web-3tier-app"
  environment        = "poc"
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  alb_sg_id          = module.network.alb_sg_id
  ecs_sg_id          = module.network.ecs_sg_id
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  db_endpoint        = module.storage.db_endpoint
  db_name            = "wordpressdb"
  db_user            = "admin"
  db_password        = var.db_password
  s3_bucket_name     = module.storage.s3_bucket_name
  efs_id             = module.storage.efs_id
}