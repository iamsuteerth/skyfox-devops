output "workspace_id" {
  description = "AWS Managed Prometheus workspace ID"
  value       = aws_prometheus_workspace.skyfox.id
}

output "workspace_endpoint" {
  description = "AWS Managed Prometheus query endpoint"
  value       = aws_prometheus_workspace.skyfox.prometheus_endpoint
}

output "workspace_arn" {
  description = "AWS Managed Prometheus workspace ARN"
  value       = aws_prometheus_workspace.skyfox.arn
}