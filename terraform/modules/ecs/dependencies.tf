data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "amp_endpoint" {
  name = "/skyfox-backend/amp-endpoint"
}

data "aws_ssm_parameter" "amp_workspace_id" {
  name = "/skyfox-backend/amp-workspace-id"
}

resource "random_id" "deployment" {
  byte_length = 4
  keepers = {
    backend_image = var.backend_image_tag
  }
}
