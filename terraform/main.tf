provider "aws" {
  profile = var.aws_profile
  region = var.aws_region
}

# --- 1. NETWORKING (VPC) ---
# Create a virtual network with Public Subnets (for Load Balancer) and Private Subnets (for application Fargate Containers)
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"
  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true # Saves money (approx $30/month), set false for high availability
}

# --- 2. SECURITY (IAM ROLES) ---

# Execution Role: Allow ECS agent to pull docker images & write logs
resource "aws_iam_role" "execution_role" {
  name = "${var.project_name}-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "exec_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Role: Allow app to read S3
resource "aws_iam_role" "task_role" {
  name = "${var.project_name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

# Allow Reading ONLY from the specific receipt bucket
resource "aws_iam_role_policy" "s3_read_policy" {
  name = "s3-read-receipts"
  role = aws_iam_role.task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.receipts.arn,
          "${aws_s3_bucket.receipts.arn}/*"
        ]
      }
    ]
  })
}

# --- 3. STORAGE (S3 & ECR) ---

# S3 Bucket for Receipts
resource "aws_s3_bucket" "receipts" {
  bucket = var.bucket_name
}

# Block all public access (Security Best Practice)
resource "aws_s3_bucket_public_access_block" "receipts" {
  bucket = aws_s3_bucket.receipts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ECR Repo to store your Docker Image
resource "aws_ecr_repository" "repo" {
  name = "${var.project_name}-repo"
  force_delete = true
}

# --- 4. LOAD BALANCER (ALB) ---
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound to Fargate
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path = "/health"
    matcher = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# --- 5. ECS FARGATE CLUSTER ---

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  vpc_id      = module.vpc.vpc_id

  # Only allow traffic from the Load Balancer (High Security)
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  # HARDWARE SIZING: Donut model is heavy. Start with the 2 vCPU (2048) and 4 GB RAM (4096).
  cpu                      = 2048
  memory                   = 4096

  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true
      portMappings = [{ containerPort = 8000, hostPort = 8000 }]

      # Pass S3 Bucket Name to Python
      environment = [
        { name = "BUCKET_NAME", value = aws_s3_bucket.receipts.bucket }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]
}