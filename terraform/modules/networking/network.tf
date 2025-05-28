# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ALB Security Group - Allow HTTP from Internet
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Load Balancer"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Internal ALB Security Group
resource "aws_security_group" "internal_alb" {
  name_prefix = "${var.project_name}-${var.environment}-internal-alb-"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-internal-alb-sg"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Internal Load Balancer"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Instance Security Group
resource "aws_security_group" "ecs_instance" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-instances-sg"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "ECS Instances"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "internal_alb_ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_instance.id
  security_group_id        = aws_security_group.internal_alb.id
  description              = "HTTP from ECS instances"
}

resource "aws_security_group_rule" "internal_alb_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ecs_instance.id
  security_group_id        = aws_security_group.internal_alb.id
  description              = "All outbound to ECS instances"
}

resource "aws_security_group_rule" "ecs_ingress_external_alb" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs_instance.id
  description              = "Dynamic ports from External ALB"
}

resource "aws_security_group_rule" "ecs_ingress_internal_alb" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_alb.id
  security_group_id        = aws_security_group.ecs_instance.id
  description              = "Dynamic ports from Internal ALB"
}

resource "aws_security_group_rule" "ecs_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_instance.id
  description       = "SSH access"
}

resource "aws_security_group_rule" "ecs_egress_internal_alb" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.internal_alb.id
  security_group_id        = aws_security_group.ecs_instance.id
  description              = "All outbound to Internal ALB"
}

resource "aws_security_group_rule" "ecs_egress_external_alb" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs_instance.id
  description              = "All outbound to External ALB"
}

resource "aws_security_group_rule" "ecs_egress_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_instance.id
  description       = "All outbound to internet"
}
