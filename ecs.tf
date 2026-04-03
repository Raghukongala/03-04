# ─────────────────────────────────────────────
# ECS Cluster
# ─────────────────────────────────────────────
resource "aws_ecs_cluster" "cluster" {
  name = "devops-ecs-cluster"
}

# ─────────────────────────────────────────────
# IAM Role for ECS Task Execution
# ─────────────────────────────────────────────
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─────────────────────────────────────────────
# ECS Task Definition
# ─────────────────────────────────────────────
resource "aws_ecs_task_definition" "task" {
  family                   = "devops-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "devops-container"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ─────────────────────────────────────────────
# ECS Service  (wired to ALB target group)
# Declared BEFORE ecs_sg so that on destroy,
# Terraform tears down the service first (draining
# all task ENIs), and only then deletes the SG.
# ─────────────────────────────────────────────
resource "aws_ecs_service" "service" {
  name            = "devops-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.ecs_min_capacity
  launch_type     = "FARGATE"

  timeouts {
    delete = "20m"
  }

  network_configuration {
    subnets          = [aws_subnet.public1.id, aws_subnet.public2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "devops-container"
    container_port   = var.app_port
  }

  depends_on = [aws_lb_listener.http]
}

# ─────────────────────────────────────────────
# Security Group – ECS Tasks
# Declared AFTER the service block so the Terraform
# destroy graph deletes the service (and drains all
# task ENIs) before attempting to delete this SG.
# This is the fix for: DependencyViolation on destroy.
# ─────────────────────────────────────────────
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_ecs_service.service]

  tags = {
    Name = "ecs-sg"
  }
}
