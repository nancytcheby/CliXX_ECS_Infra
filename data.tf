# ----------------------------------------
# Data Sources
# ----------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "main" {
  name         = "nancy-stack.com."
  private_zone = false
}

data "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceRole"
}

data "aws_secretsmanager_secret" "ecr_config" {
  name = "clixx/ecr-config"
}

data "aws_secretsmanager_secret_version" "ecr_config" {
  secret_id = data.aws_secretsmanager_secret.ecr_config.id
}

locals {
  ecr_config = jsondecode(data.aws_secretsmanager_secret_version.ecr_config.secret_string)
}