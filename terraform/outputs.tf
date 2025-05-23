output "vpc_id" {
  value = module.networking.vpc_id
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}