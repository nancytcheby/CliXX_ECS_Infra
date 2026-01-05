########################
# ECS Outputs
########################

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.clixx_cluster.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.clixx_service.name
}

output "ecs_alb_dns_name" {
  description = "DNS name of the ECS ALB"
  value       = aws_lb.ecs_alb.dns_name
}

output "ecs_url" {
  description = "URL to access the ECS application"
  value       = "http://ecs.${var.root_domain}"
}