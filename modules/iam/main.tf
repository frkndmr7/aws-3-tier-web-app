# 1. ECS Task Execution Role (AWS'nin standart izni: ECR ve Loglar için)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# AWS'nin hazır "AmazonECSTaskExecutionRolePolicy" politikasını bu role bağlıyoruz
resource "aws_iam_role_policy_attachment" "ecs_execution_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. ECS Task Role (WordPress'in S3'e yazabilmesi için)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Özel S3 Politikası (Sadece bizim bucket'ımıza izin veriyoruz - Least Privilege!)
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-s3-access"
  description = "Allow WordPress to access S3 media bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
        Effect   = "Allow"
        Resource = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}