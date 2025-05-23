output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for idx, repo in aws_ecr_repository.repositories :
    var.repository_names[idx] => repo.repository_url
  }
}

output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value = {
    for idx, repo in aws_ecr_repository.repositories :
    var.repository_names[idx] => repo.arn
  }
}

output "repository_names" {
  description = "Names of the ECR repositories"
  value = {
    for idx, repo in aws_ecr_repository.repositories :
    var.repository_names[idx] => repo.name
  }
}

output "registry_id" {
  description = "The registry ID where the repositories were created"
  value       = aws_ecr_repository.repositories[0].registry_id
}
