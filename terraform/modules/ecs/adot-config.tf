locals {
  adot_config = templatefile("${path.module}/adot-config.yaml", {
    ecs_cluster_name = aws_ecs_cluster.main.name
    deployment_id = random_id.deployment.hex
    amp_full_endpoint = "${data.aws_ssm_parameter.amp_endpoint.value}api/v1/remote_write"
    backend_port = var.backend_port
    backend_container_name = var.backend_container_name
  })
}

resource "aws_ssm_parameter" "adot_config" {
  name  = "/skyfox-backend/adot-config"
  type  = "String"
  value = local.adot_config

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}