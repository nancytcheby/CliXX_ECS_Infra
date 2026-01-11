# ----------------------------------------
# Environment and Account Configuration
# ----------------------------------------

variable "env" {
  description = "Environment name (dev, test, aut, prod)"
  type        = string
  default     = "aut"
  
  validation {
    condition     = contains(["dev", "test", "aut", "prod"], var.env)
    error_message = "Environment must be one of: dev, test, aut, prod."
  }
}

variable "accounts" {
  description = "Map of environment to AWS account IDs"
  type        = map(string)
  default = {
    admin = "135576900189" 
    dev   = "083587468058"
    test  = "279271292861"
    aut   = "818760291841"
    prod  = "767076727117"
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# ----------------------------------------
# VPC Configuration
# ----------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Public Subnets - ALB & Bastion (450 hosts each)
variable "public_subnets" {
  description = "Map of public subnet names to CIDR blocks"
  type        = map(string)
  default = {
    "public-1" = "10.0.0.0/23"
    "public-2" = "10.0.2.0/23"
  }
}

# Private Subnets - Web/Application Servers (250 hosts each)
variable "private_web_subnets" {
  description = "Map of private web server subnet names to CIDR blocks"
  type        = map(string)
  default = {
    "private-web-1" = "10.0.4.0/24"
    "private-web-2" = "10.0.5.0/24"
  }
}

# Private Subnets - RDS MySQL Database (680 hosts each)
variable "private_rds_subnets" {
  description = "Map of private RDS subnet names to CIDR blocks"
  type        = map(string)
  default = {
    "private-rds-1" = "10.0.8.0/22"
    "private-rds-2" = "10.0.12.0/22"
  }
}

# Private Subnets - Oracle Database (254 hosts each)
variable "private_oracle_subnets" {
  description = "Map of private Oracle DB subnet names to CIDR blocks"
  type        = map(string)
  default = {
    "private-oracle-1" = "10.0.16.0/24"
    "private-oracle-2" = "10.0.17.0/24"
  }
}

# Private Subnets - Java Database (50 hosts each)
variable "private_java_db_subnets" {
  description = "Map of private Java DB subnet names to CIDR blocks"
  type        = map(string)
  default = {
    "private-java-db-1" = "10.0.18.0/26"
    "private-java-db-2" = "10.0.18.64/26"
  }
}

# Private Subnets - Java Application Servers (50 hosts each)
variable "private_java_app_subnets" {
  description = "Map of private Java app server subnet names to CIDR blocks"
  type        = map(string)
  default = {
    "private-java-app-1" = "10.0.18.128/26"
    "private-java-app-2" = "10.0.18.192/26"
  }
}

# ----------------------------------------
# Database Configuration
# ----------------------------------------

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "wordpressuser"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpressdb"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_snapshot_identifier" {
  description = "RDS snapshot identifier to restore from"
  type        = string
  default     = "arn:aws:rds:us-east-1:577701061234:snapshot:wordpressdbclixx-ecs-snapshot"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# ----------------------------------------
# Route53 / DNS Configuration
# ----------------------------------------

variable "root_domain" {
  description = "Root hosted zone domain name"
  type        = string
  default     = "nancy-stack.com"
}

# ----------------------------------------
# ECS Configuration
# ----------------------------------------

variable "ecs_task_cpu" {
  description = "CPU units for ECS task"
  type        = string
  default     = "512"
}

variable "ecs_task_memory" {
  description = "Memory (MB) for ECS task"
  type        = string
  default     = "1024"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

# ----------------------------------------
# ECS EC2 Configuration
# ----------------------------------------

variable "ecs_ami_id" {
  description = "ECS-optimized AMI ID"
  type        = string
  default     = "ami-0ca37b07dab0da592"  
}

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS"
  type        = string
  default     = "t3.medium"
}

variable "ecs_desired_capacity" {
  description = "Desired number of ECS instances"
  type        = number
  default     = 2
}

variable "ecs_min_size" {
  description = "Minimum number of ECS instances"
  type        = number
  default     = 1
}

variable "ecs_max_size" {
  description = "Maximum number of ECS instances"
  type        = number
  default     = 4
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "clixx"
}