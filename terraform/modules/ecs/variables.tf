variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Networking inputs (from networking/outputs.tf)
variable "vpc_id" {
  description = "VPC ID where ECS resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where ECS instances will be launched"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (for backend service only)"
  type        = list(string)
}

variable "backend_security_group_id" {
  description = "Security group ID for backend service"
  type        = string
}

variable "payment_security_group_id" {
  description = "Security group ID for payment service"
  type        = string
}

variable "movie_security_group_id" {
  description = "Security group ID for movie service"
  type        = string
}

variable "ecs_instance_security_group_id" {
  description = "Security group ID for ECS instances"
  type        = string
}

# ECR inputs (from ecr/outputs.tf)
variable "repository_urls" {
  description = "ECR repository URLs for container images"
  type        = map(string)
}

# ECS Cluster Configuration
variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t4g.small"  
}

variable "min_capacity" {
  description = "Minimum number of EC2 instances in ASG"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of EC2 instances in ASG"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in ASG"
  type        = number
  default     = 2
}

# Task Configuration 
variable "backend_cpu" {
  description = "CPU units for backend service (1024 = 1 vCPU)"
  type        = number
  default     = 475  # 0.450 vCPU
}

variable "backend_memory" {
  description = "Memory for backend service in MiB"
  type        = number
  default     = 819  # 0.8 GiB
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 2
}

variable "backend_max_capacity" {
  description = "Maximum number of backend tasks"
  type        = number
  default     = 4
}

variable "payment_cpu" {
  description = "CPU units for payment service"
  type        = number
  default     = 230  # 0.23 vCPU
}

variable "payment_memory" {
  description = "Memory for payment service in MiB"
  type        = number
  default     = 410  # 0.4 GiB
}

variable "payment_desired_count" {
  description = "Desired number of payment tasks"
  type        = number
  default     = 2
}

variable "payment_max_capacity" {
  description = "Maximum number of payment tasks"
  type        = number
  default     = 3
}

variable "movie_cpu" {
  description = "CPU units for movie service"
  type        = number
  default     = 230  # 0.23 vCPU
}

variable "movie_memory" {
  description = "Memory for movie service in MiB"
  type        = number
  default     = 410  # 0.4 GiB
}

variable "movie_desired_count" {
  description = "Desired number of movie tasks"
  type        = number
  default     = 2
}

variable "movie_max_capacity" {
  description = "Maximum number of movie tasks"
  type        = number
  default     = 3
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
