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

variable "force_deployment" {
  description = "Force new deployment of ECS services"
  type        = bool
  default     = false
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}