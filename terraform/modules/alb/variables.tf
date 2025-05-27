variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Networking inputs
variable "vpc_id" {
  description = "VPC ID where ALB resources will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for external ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for internal ALB"
  type        = list(string)
}

# Security group inputs
variable "alb_security_group_id" {
  description = "Security group ID for external ALB"
  type        = string
}

variable "internal_alb_security_group_id" {
  description = "Security group ID for internal ALB"
  type        = string
}

# ECS inputs 
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

# Service ports
variable "backend_port" {
  description = "Port for backend service"
  type        = number
  default     = 8080
}

variable "payment_port" {
  description = "Port for payment service"
  type        = number
  default     = 8082
}

variable "movie_port" {
  description = "Port for movie service"
  type        = number
  default     = 4567
}
