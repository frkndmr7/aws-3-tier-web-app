# 1. VPC Oluşturma
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# 2. İnternet Gateway (Dış dünyaya açılan kapı)
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# 3. Public Subnetler (Verileri otomatik olarak farklı bölgelere dağıtır)
data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Bu subnet'e giren cihazlar IP alsın

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
  }
}

# 4. Route Table (Trafik nereye gitsin?)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# 5. Subnetleri Route Table'a bağlama
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 1. ALB için Güvenlik Grubu (Dış dünyaya açık)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. ECS Fargate için Güvenlik Grubu (Sadece ALB'den gelenleri alır)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Traffic from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Zincirleme bağlantı!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. RDS için Güvenlik Grubu (Sadece ECS'den gelenleri alır)
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Allow traffic from ECS only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "MariaDB from ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id] # Sadece App katmanı erişebilir
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}