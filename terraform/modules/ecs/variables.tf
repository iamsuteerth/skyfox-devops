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

variable "public_subnet_ids" {
  description = "Public subnet IDs (for backend service only)"
  type        = list(string)
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

variable "deploy_services" {
  description = "Whether to deploy ECS services (set to false for initial infrastructure deployment)"
  type        = bool
  default     = false
}

# ECS Cluster Configuration
variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t4g.small"  
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = null
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
  default     = 896
}

variable "backend_memory" {
  description = "Memory for backend service in MiB"
  type        = number
  default     = 832  # 0.8 GiB
}

variable "adot_cpu" {
  description = "CPU units for ADOT sidecar "
  type        = number
  default = 128
}

variable "adot_memory" {
  description = "Memory for ADOT sidecar in MiB"
  type        = number
  default     = 128  # 0.1 GiB
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
  default     = 384  
}

variable "payment_memory" {
  description = "Memory for payment service in MiB"
  type        = number
  default     = 448  # 0.4 GiB
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
  default     = 384 
}

variable "movie_memory" {
  description = "Memory for movie service in MiB"
  type        = number
  default     = 448  # 0.4 GiB
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

variable "movie_service_url" {
  description = "URL for movie service (from ALB output)"
  type        = string
}

variable "payment_gateway_url" {
  description = "URL for payment gateway (from ALB output)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for profile images"
  type        = string
}

variable "backend_target_group_arn" {
  description = "ARN of the backend target group"
  type        = string
}

variable "payment_target_group_arn" {
  description = "ARN of the payment target group"
  type        = string
}

variable "movie_target_group_arn" {
  description = "ARN of the movie target group"
  type        = string
}

# Auto Scaling Configuration
variable "enable_auto_scaling" {
  description = "Enable auto scaling for ECS services"
  type        = bool
  default     = false
}

variable "backend_cpu_target" {
  description = "Target CPU utilization for backend auto scaling"
  type        = number
  default     = 70
}

variable "backend_memory_target" {
  description = "Target memory utilization for backend auto scaling"
  type        = number
  default     = 80
}

variable "payment_cpu_target" {
  description = "Target CPU utilization for payment auto scaling"
  type        = number
  default     = 70
}

variable "payment_memory_target" {
  description = "Target memory utilization for payment auto scaling"
  type        = number
  default     = 80
}

variable "movie_cpu_target" {
  description = "Target CPU utilization for movie auto scaling"
  type        = number
  default     = 70
}

variable "movie_memory_target" {
  description = "Target memory utilization for movie auto scaling"
  type        = number
  default     = 80
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
  description = "Force new deployment of ALL services"
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

variable "backend_container_name" {
  description = "Container name for backend tasks"
  type = string
  default = "backend"
}

variable "movie_container_name" {
  description = "Container name for movie tasks"
  type = string
  default = "movie"
}

variable "payment_container_name" {
  description = "Container name for payment tasks"
  type = string
  default = "payment"
}

variable "adot_container_name" {
  description = "Container name for adot tasks"
  type = string
  default = "adot-collector"
}
