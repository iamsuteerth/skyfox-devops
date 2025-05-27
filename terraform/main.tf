# Networking Module
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name 
  environment  = var.environment   
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  environment  = var.environment
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"
  
  project_name = var.project_name
  environment  = var.environment
  
  # Networking inputs
  vpc_id                        = module.networking.vpc_id
  public_subnet_ids             = module.networking.public_subnet_ids
  private_subnet_ids            = module.networking.private_subnet_ids
  backend_security_group_id     = module.networking.backend_security_group_id
  payment_security_group_id     = module.networking.payment_security_group_id
  movie_security_group_id       = module.networking.movie_security_group_id
  ecs_instance_security_group_id = module.networking.ecs_instance_security_group_id
  
  # ECR inputs
  repository_urls = module.ecr.repository_urls
}