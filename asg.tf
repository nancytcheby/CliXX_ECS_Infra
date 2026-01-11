
# ----------------------------------------
# Security Group for ECS EC2 Instances
# ----------------------------------------

resource "aws_security_group" "ecs_instances_sg" {
  name        = "${var.project_name}-ecs-instances-sg-${var.env}"
  description = "Security group for ECS EC2 instances"
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
    Name = "${var.project_name}-ecs-instances-sg-${var.env}"
  }
}

# ----------------------------------------
# Launch Template for ECS Instances
# ----------------------------------------

resource "aws_launch_template" "ecs_launch_template" {
  name          = "${var.project_name}-ecs-lt-${var.env}"
  image_id      = var.ecs_ami_id
  instance_type = var.ecs_instance_type

  iam_instance_profile {
    name = data.aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ecs_instances_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.clixx_cluster.name} >> /etc/ecs/ecs.config
              
              # Install MySQL 
              yum install -y mariadb105
              
              # Wait for RDS to be ready
              sleep 180
              
              # Update WordPress URLs 
              mysql -h ${aws_db_instance.clixx_db.address} -u ${var.db_username} -p${var.db_password} ${var.db_name} -e "UPDATE wp_options SET option_value='http://ecs.${var.root_domain}' WHERE option_value LIKE '%nlb%';"
              
              echo "WordPress URLs updated"
              EOF
  )

  tags = {
    Name = "${var.project_name}-ecs-lt-${var.env}"
  }
}

# ----------------------------------------
# Auto Scaling Group
# ----------------------------------------

resource "aws_autoscaling_group" "ecs_asg" {
  name                = "${var.project_name}-ecs-asg-${var.env}"
  desired_capacity    = var.ecs_desired_capacity
  max_size            = var.ecs_max_size
  min_size            = var.ecs_min_size
  vpc_zone_identifier = [for subnet in aws_subnet.private_web_subnet : subnet.id]

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance-${var.env}"
    propagate_at_launch = true
  }
}

