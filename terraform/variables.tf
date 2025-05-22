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
