########################
# ECS Cluster
########################

resource "aws_ecs_cluster" "clixx_cluster" {
  name = "clixx-ecs-cluster-${var.env}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "clixx-ecs-cluster-${var.env}"
  }
}

########################
# Use Existing ECS Task Execution Role
########################

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

########################
# CloudWatch Log Group
########################

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/clixx-${var.env}"
  retention_in_days = 30

  tags = {
    Name = "clixx-ecs-logs-${var.env}"
  }
}

########################
# ECS Task Definition
########################

resource "aws_ecs_task_definition" "clixx_task" {
  family                   = "clixx-task-${var.env}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "clixx-container"
      image     = "${var.ecr_repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = aws_db_instance.clixx_db.address
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = var.database_config["username"]
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = var.database_config["db_name"]
        },
        {
           name  = "WORDPRESS_DB_PASSWORD"
           value = var.db_password
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "clixx-task-definition-${var.env}"
  }
}

########################
# Security Group - ALB
########################

resource "aws_security_group" "ecs_alb_sg" {
  name        = "clixx-ecs-alb-sg-${var.env}"
  description = "Security group for ECS ALB"
  vpc_id      = aws_vpc.clixx_vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "clixx-ecs-alb-sg-${var.env}"
  }
}

########################
# Security Group - ECS Tasks
########################

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "clixx-ecs-tasks-sg-${var.env}"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.clixx_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "clixx-ecs-tasks-sg-${var.env}"
  }
}

########################
# Application Load Balancer
########################

resource "aws_lb" "ecs_alb" {
  name               = "clixx-ecs-alb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]

  enable_deletion_protection = false

  tags = {
    Name = "clixx-ecs-alb-${var.env}"
  }
}

########################
# ALB Target Group
########################

resource "aws_lb_target_group" "ecs_tg" {
  name        = "clixx-ecs-tg-${var.env}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.clixx_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,301,302"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name = "clixx-ecs-tg-${var.env}"
  }
}

########################
# ALB Listener
########################

resource "aws_lb_listener" "ecs_http" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

########################
# ECS Service
########################

resource "aws_ecs_service" "clixx_service" {
  name            = "clixx-service-${var.env}"
  cluster         = aws_ecs_cluster.clixx_cluster.id
  task_definition = aws_ecs_task_definition.clixx_task.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "EC2"

  network_configuration {
    subnets          = [for subnet in aws_subnet.private_web_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "clixx-container"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.ecs_http
  ]

  tags = {
    Name = "clixx-ecs-service-${var.env}"
  }
}

########################
# Route53 Record for ECS
########################

resource "aws_route53_record" "ecs_record" {
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = "ecs.${var.root_domain}"
  type     = "CNAME"
  ttl      = 300
  records  = [aws_lb.ecs_alb.dns_name]
  allow_overwrite = true
}


