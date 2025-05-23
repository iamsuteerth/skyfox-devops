provider "aws" {
  region = "ap-south-1"
}

# Remote State Config
terraform {
  backend "s3" {
    bucket = "skyfox-terraform-state"
    key = "global/s3/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "skyfox-terraform-locks"
    encrypt = true
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  project_name = var.project_name 
  environment  = var.environment   
}