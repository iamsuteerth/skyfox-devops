output "vpc_id" {
  value = module.networking.vpc_id
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
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