# ECR Repositories
resource "aws_ecr_repository" "repositories" {
  count = length(var.repository_names)

  name                 = "${var.project_name}-${var.environment}-${var.repository_names[count.index]}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true 

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.repository_names[count.index]}"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.repository_names[count.index]
  }
}

# Lifecycle Policy for all repositories
resource "aws_ecr_lifecycle_policy" "repositories_policy" {
  count = length(aws_ecr_repository.repositories)

  repository = aws_ecr_repository.repositories[count.index].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${var.lifecycle_policy_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.lifecycle_policy_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Repository Policy for cross-account access 
resource "aws_ecr_repository_policy" "repositories_policy" {
  count = length(aws_ecr_repository.repositories)

  repository = aws_ecr_repository.repositories[count.index].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
      }
    ]
  })
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}