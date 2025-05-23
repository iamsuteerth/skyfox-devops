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