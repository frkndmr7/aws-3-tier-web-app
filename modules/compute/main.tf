# 1. Application Load Balancer (ALB) - İnternet Kapısı
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
    path = "/" # WordPress'in ayakta olup olmadığını kontrol eder
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

# 2. ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

# 3. Task Definition (Konteynerin Tarifi)
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512" # 0.5 vCPU
  memory                   = "1024" # 1GB RAM
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = "wordpress:latest" # Şimdilik resmi imaj, sonra ECR'ye geçeceğiz
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
      # Logları izlemek için CloudWatch ayarı (Senior dokunuşu)
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

# CloudWatch Log Group (Loglar buraya akacak)
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/wordpress"
}

# 4. ECS Service (Konteyneri çalıştıran motor)
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 2 # Her zaman 2 tane çalışsın (Yedeklilik!)
  launch_type     = "FARGATE"

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