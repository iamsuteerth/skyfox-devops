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

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
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

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt"
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

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ALB Security Group - Allow HTTP from Internet
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = aws_vpc.main.id

  # HTTP ingress
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS ingress (if enabled)
  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # All outbound traffic
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

# Backend Service Security Group
resource "aws_security_group" "backend" {
  name_prefix = "${var.project_name}-${var.environment}-backend-"
  vpc_id      = aws_vpc.main.id

  # Backend port from ALB
  ingress {
    description     = "Backend API"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # All outbound (for Supabase connectivity)
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-sg"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Backend Service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Payment Service Security Group
resource "aws_security_group" "payment" {
  name_prefix = "${var.project_name}-${var.environment}-payment-"
  vpc_id      = aws_vpc.main.id

  # Payment port from ALB only
  ingress {
    description     = "Payment API"
    from_port       = var.payment_port
    to_port         = var.payment_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # No outbound internet (internal service only)
  egress {
    description = "Internal VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-payment-sg"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Payment Service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Movie Service Security Group
resource "aws_security_group" "movie" {
  name_prefix = "${var.project_name}-${var.environment}-movie-"
  vpc_id      = aws_vpc.main.id

  # Movie port from ALB only
  ingress {
    description     = "Movie API"
    from_port       = var.movie_port
    to_port         = var.movie_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # No outbound internet (internal service only)
  egress {
    description = "Internal VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-movie-sg"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Movie Service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Instance Security Group
resource "aws_security_group" "ecs_instance" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-"
  vpc_id      = aws_vpc.main.id

  # Allow traffic from service security groups
  ingress {
    description     = "Backend traffic"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  ingress {
    description     = "Payment traffic"
    from_port       = var.payment_port
    to_port         = var.payment_port
    protocol        = "tcp"
    security_groups = [aws_security_group.payment.id]
  }

  ingress {
    description     = "Movie traffic"
    from_port       = var.movie_port
    to_port         = var.movie_port
    protocol        = "tcp"
    security_groups = [aws_security_group.movie.id]
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

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