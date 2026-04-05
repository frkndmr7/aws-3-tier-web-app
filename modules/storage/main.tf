# 1. DB Subnet Group (RDS'in hangi mahallelerde oturacağını söyler)
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# 2. MariaDB Instance (Maliyet dökümanındaki ayarlarla)
resource "aws_db_instance" "this" {
  identifier           = "${var.project_name}-${var.environment}-db"
  engine               = "mariadb"
  engine_version       = "10.11" # Güncel kararlı sürüm
  instance_class       = "db.t4g.micro" # Ucuz ve performanslı Graviton
  allocated_storage     = 30 # Senin dökümanındaki 30GB
  db_name              = var.db_name
  username             = var.db_user
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  skip_final_snapshot  = true # POC biterken silmeyi kolaylaştırır
  publicly_accessible  = true # POC aşamasında bağlanıp kontrol edebilmen için

  tags = {
    Name = "${var.project_name}-${var.environment}-mariadb"
  }
}

# 1. Media İçerikleri için S3 Bucket
resource "aws_s3_bucket" "media_bucket" {
  bucket = "${var.project_name}-${var.environment}-media-9922" # Benzersiz isim

  tags = {
    Name = "${var.project_name}-media-storage"
  }
}

# Bucket'ın dışarıya (CloudFront'a) açık olması için gerekli temel ayar
resource "aws_s3_bucket_public_access_block" "media_access" {
  bucket = aws_s3_bucket.media_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3. CloudFront'un içeri girmesini sağlayan "Bucket Policy" (YENİ)




# 2. EFS (Sadece Plugins ve Themes için - Minimum Boyutta)
resource "aws_efs_file_system" "wp_shared_files" {
  creation_token = "${var.project_name}-efs"
  performance_mode = "generalPurpose" # En ucuz ve stabil mod
  throughput_mode  = "bursting"

  tags = {
    Name = "${var.project_name}-shared-config"
  }
}

# EFS Dağıtım Noktaları (Önceki kodla aynı)
resource "aws_efs_mount_target" "this" {
  count           = length(var.public_subnet_ids)
  file_system_id  = aws_efs_file_system.wp_shared_files.id
  subnet_id       = var.public_subnet_ids[count.index]
  security_groups = [var.db_sg_id]
}