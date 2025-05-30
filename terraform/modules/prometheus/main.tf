resource "aws_prometheus_workspace" "skyfox" {
    alias  = "${var.project_name}-${var.environment}-metrics"

    tags = {
      Name = "${var.project_name}-${var.environment}-prometheus"
      Environment = var.environment
      Project = var.project_name
    }
}

resource "aws_ssm_parameter" "amp_workspace_id" {
  name  = "/skyfox-backend/amp-workspace-id"
  type  = "String"
  value = aws_prometheus_workspace.skyfox.id

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ssm_parameter" "amp_endpoint" {
  name  = "/skyfox-backend/amp-endpoint"
  type  = "String"
  value = aws_prometheus_workspace.skyfox.prometheus_endpoint

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}