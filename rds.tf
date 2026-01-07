########################
# RDS Security Group
########################

resource "aws_security_group" "rds_sg" {
  name        = "clixx-rds-sg-${var.env}"
  description = "Security group for RDS MySQL"
  vpc_id      = aws_vpc.clixx_vpc.id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "clixx-rds-sg-${var.env}"
  }
}

########################
# RDS Subnet Group
########################

resource "aws_db_subnet_group" "clixx_db_subnet_group" {
  name       = "clixx-db-subnet-group-${var.env}"
  subnet_ids = [for subnet in aws_subnet.private_rds_subnet : subnet.id]

  tags = {
    Name = "clixx-db-subnet-group-${var.env}"
  }
}

########################
# RDS Instance from Snapshot
########################

resource "aws_db_instance" "clixx_db" {
  identifier     = "clixx-db-${var.env}"
  instance_class = var.rds_instance_class

  # Restore from snapshot
  snapshot_identifier = var.db_snapshot_identifier

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.clixx_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Storage
  allocated_storage = 20
  storage_type      = "gp2"

  # Settings
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false

  # Apply changes immediately during destroy/rebuild
  apply_immediately = true

  tags = {
    Name = "clixx-db-${var.env}"
  }
}