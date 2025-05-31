variable "project_name" {
  description = "Deployment Ecosystem for Backend"
  type        = string
  default     = "skyfox"
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
  default     = "devprod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "deploy_services" {
  description = "Deploy ECS services"
  type        = bool
  default     = false
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for ECS services"
  type        = bool
  default     = false
}

variable "force_backend_deployment" {
  description = "Force new deployment of backend service only"
  type        = bool
  default     = false
}

variable "force_payment_deployment" {
  description = "Force new deployment of payment service only"
  type        = bool
  default     = false
}

variable "force_movie_deployment" {
  description = "Force new deployment of movie service only"  
  type        = bool
  default     = false
}

variable "force_deployment" {
  description = "Force new deployment of ECS services"
  type        = bool
  default     = false
}

variable "backend_image_tag" {
  description = "Container image tag for backend service"
  type        = string
  default     = "latest"
}

variable "payment_image_tag" {
  description = "Container image tag for payment service"
  type        = string
  default     = "latest"
}

variable "movie_image_tag" {
  description = "Container image tag for movie service"
  type        = string
  default     = "latest"
}

variable "adot_image_tag" {
  description = "Container image tag for backend service adot collector"
  type        = string
  default     = "latest"
}