# Remote State Config
terraform {
  backend "s3" {
    bucket         = "skyfox-terraform-state"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "skyfox-terraform-locks"
    encrypt        = true
  }
}
