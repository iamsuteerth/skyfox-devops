resource "aws_efs_file_system" "adot_config" {
  creation_token = "${var.project_name}-${var.environment}-adot-config"
  encrypted = true
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-adot-config"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_efs_access_point" "adot_config" {
  file_system_id = aws_efs_file_system.adot_config.id
  
  posix_user {
    gid = 1001
    uid = 1001
  }
  
  root_directory {
    path = "/adot"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "755"
    }
  }
  
  tags = {
    Name = "${var.project_name}-${var.environment}-adot-access-point"
  }
}

resource "aws_security_group" "efs" {
  name_prefix = "${var.project_name}-${var.environment}-efs"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [var.ecs_instance_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-efs-sg"
  }
}

resource "aws_efs_mount_target" "adot_config" {
  count           = length(var.public_subnet_ids)
  file_system_id  = aws_efs_file_system.adot_config.id
  subnet_id       = var.public_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

locals {
  adot_config = templatefile("${path.module}/adot-config.yaml", {
    amp_endpoint = "https://aps-workspaces.${data.aws_region.current.name}.amazonaws.com/workspaces"
    ecs_cluster_name = aws_ecs_cluster.main.name
    deployment_id = random_id.deployment.hex
  })
}

data "aws_region" "current" {}

resource "aws_ssm_parameter" "adot_config" {
  name  = "/skyfox-backend/adot-config"
  type  = "String"
  value = local.adot_config

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}