variable "project_name" {
  description = "Deployment Ecosystem for Backend"
  type        = string
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "enable_https" {
  description = "Enable HTTPS on ALB"
  type        = bool
  default     = false
}

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