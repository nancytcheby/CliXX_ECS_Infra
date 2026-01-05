# ----------------------------------------
# Data Sources
# ----------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "main" {
  name         = var.root_domain
  private_zone = false
}
