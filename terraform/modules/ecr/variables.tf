variable "project_name" {
  description = "Name of the project"
  type = string
}

variable "environment" {
  description = "Environment Name"
  type = string
}

variable "repository_names" {
  description = "List of ECR Repository Names"
  type = list(string)
  default = [ "backend", "payment-service", "movie-service", "adot" ]
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "lifecycle_policy_days" {
  description = "Number of days to retain untagged images"
  type        = number
  default     = 3
}

variable "max_image_count" {
  description = "Maximum number of images to retain"
  type        = number
  default     = 4
}