module "networking" {
  source = "./modules/networking"

  project_name = var.project_name 
  environment  = var.environment   
}

module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  environment  = var.environment
}

module "ecs" {
  source = "./modules/ecs"
  
  project_name = var.project_name
  environment  = var.environment
  
  # Networking inputs
  vpc_id                        = module.networking.vpc_id
  public_subnet_ids             = module.networking.public_subnet_ids
  backend_security_group_id     = module.networking.backend_security_group_id
  payment_security_group_id     = module.networking.payment_security_group_id
  movie_security_group_id       = module.networking.movie_security_group_id
  ecs_instance_security_group_id = module.networking.ecs_instance_security_group_id

  # EC2 Key Pair
  key_pair_name = "skyfox-key"
  
  # ECR inputs
  repository_urls = module.ecr.repository_urls

  # ALB inputs
  movie_service_url    = "${module.alb.internal_alb_url}/movie-service"
  payment_gateway_url  = "${module.alb.internal_alb_url}/payment-service"
  backend_target_group_arn  = module.alb.backend_target_group_arn
  payment_target_group_arn  = module.alb.payment_target_group_arn
  movie_target_group_arn    = module.alb.movie_target_group_arn
  
  # S3 inputs
  s3_bucket_name = module.s3.bucket_name
}

module "alb" {
  source = "./modules/alb"
  
  project_name = var.project_name
  environment  = var.environment
  
  # Networking inputs
  vpc_id                        = module.networking.vpc_id
  public_subnet_ids             = module.networking.public_subnet_ids
  alb_security_group_id         = module.networking.alb_security_group_id
  internal_alb_security_group_id = module.networking.internal_alb_security_group_id
  
  # ECS inputs
  ecs_cluster_name = module.ecs.cluster_name
}
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
}