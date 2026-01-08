# ----------------------------------------
# Data Sources
# ----------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "main" {
  provider     = aws.dev_account
  name         = "nancy-stack.com."
  private_zone = false
}

data "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceRole"
}