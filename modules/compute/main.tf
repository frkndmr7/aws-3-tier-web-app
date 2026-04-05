# 1. Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "wp_tg" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    matcher             = "200-399" 
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}

# --- IAM: S3 İÇİN KİMLİK VE YETKİLER (YENİ EKLENDİ) ---

# ECS Task'ı için "Kimlik" (Role) oluşturuyoruz
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-task-role-new" # Çakışma olmasın diye sonuna -new ekledim

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# S3 İzinlerini bu kimliğe bağlıyoruz
resource "aws_iam_role_policy" "ecs_s3_policy" {
  name = "${var.project_name}-s3-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketAcl"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::web-3tier-app-poc-media",
          "arn:aws:s3:::web-3tier-app-poc-media/*"
        ]
      }
    ]
  })
}

# 2. ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

# 3. Task Definition
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512" 
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn
  
  
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = "wordpress:latest"
      cpu       = 512
      memory    = 1024
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
      environment = [
        { name = "WORDPRESS_DB_HOST", value = var.db_endpoint },
        { name = "WORDPRESS_DB_USER", value = var.db_user },
        { name = "WORDPRESS_DB_PASSWORD", value = var.db_password },
        { name = "WORDPRESS_DB_NAME", value = var.db_name }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/wordpress"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/wordpress"
}

# 4. ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  # Senior Notu: Task Definition her değiştiğinde servisin taze task başlatması için:
  force_new_deployment = true

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wp_tg.arn
    container_name   = "wordpress"
    container_port   = 80
  }
}