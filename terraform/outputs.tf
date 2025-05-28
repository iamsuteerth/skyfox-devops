output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.ecs.autoscaling_group_name
}

output "ecs_instance_role_arn" {
  description = "ECS instance role ARN"
  value       = module.ecs.ecs_instance_role_arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = module.ecs.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = module.ecs.ecs_task_role_arn
}

output "external_alb_url" {
  description = "URL of the external Application Load Balancer"
  value       = module.alb.external_alb_url
}

output "external_alb_dns_name" {
  description = "DNS name of the external Application Load Balancer"
  value       = module.alb.external_alb_dns_name
}

output "internal_alb_url" {
  description = "URL of the internal Application Load Balancer"
  value       = module.alb.internal_alb_url
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal Application Load Balancer"
  value       = module.alb.internal_alb_dns_name
}

output "backend_target_group_arn" {
  description = "ARN of the backend target group for ECS service registration"
  value       = module.alb.backend_target_group_arn
}

output "payment_target_group_arn" {
  description = "ARN of the payment target group for ECS service registration"
  value       = module.alb.payment_target_group_arn
}

output "movie_target_group_arn" {
  description = "ARN of the movie target group for ECS service registration"
  value       = module.alb.movie_target_group_arn
}

output "backend_environment_variables" {
  description = "Environment variables for backend service"
  value       = module.alb.backend_environment_variables
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for profile images"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}