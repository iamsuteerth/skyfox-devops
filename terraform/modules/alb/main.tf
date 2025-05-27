# External ALB
resource "aws_lb" "external" {
  name               = "${var.project_name}-${var.environment}-external-alb"
  internal           = false 
  load_balancer_type = "application"
  
  security_groups = [var.alb_security_group_id]
  subnets = var.public_subnet_ids
  
  drop_invalid_header_fields = true
  enable_http2 = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-external-alb"
    Environment = var.environment
    Project     = var.project_name
    Type        = "external"
  }
}

# External ALB Target Group
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-${var.environment}-backend-tg"
  port        = var.backend_port 
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance" 

  health_check {
    enabled             = true
    healthy_threshold   = 2     
    interval            = 30    
    matcher             = "200" 
    path                = "/health" 
    port                = "traffic-port" 
    protocol            = "HTTP"
    timeout             = 5     
    unhealthy_threshold = 2    
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-tg"
    Environment = var.environment
    Project     = var.project_name
    Service     = "backend"
  }
}

# External ALB Listener
resource "aws_lb_listener" "external" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"   
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-external-listener"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Internal ALB
resource "aws_lb" "internal" {
  name               = "${var.project_name}-${var.environment}-internal-alb"
  internal           = true   
  load_balancer_type = "application"
  
  security_groups = [var.internal_alb_security_group_id]
  subnets = var.private_subnet_ids
  
  enable_http2 = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-internal-alb"
    Environment = var.environment
    Project     = var.project_name
    Type        = "internal"
  }
}

# Internal ALB Target Group - Payment Service
resource "aws_lb_target_group" "payment" {
  name        = "${var.project_name}-${var.environment}-payment-tg"
  port        = var.payment_port 
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/pshealth"  
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-payment-tg"
    Environment = var.environment
    Project     = var.project_name
    Service     = "payment"
  }
}

# Internal ALB Target Group - Movie Service
resource "aws_lb_target_group" "movie" {
  name        = "${var.project_name}-${var.environment}-movie-tg"
  port        = var.movie_port    
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/mshealth" 
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-movie-tg"
    Environment = var.environment
    Project     = var.project_name
    Service     = "movie"
  }
}

# Internal ALB Listener
resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-internal-listener"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Routes /payment-service/* to payment service
resource "aws_lb_listener_rule" "payment" {
  listener_arn = aws_lb_listener.internal.arn
  priority     = 100 

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment.arn
  }

  condition {
    path_pattern {
      values = ["/payment-service*"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-payment-rule"
    Environment = var.environment
    Project     = var.project_name
    Service     = "payment"
  }
}

# Routes /movie-service/* to movie service
resource "aws_lb_listener_rule" "movie" {
  listener_arn = aws_lb_listener.internal.arn
  priority     = 200  # Higher number = lower priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.movie.arn
  }

  condition {
    path_pattern {
      values = ["/movie-service*"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-movie-rule"
    Environment = var.environment
    Project     = var.project_name
    Service     = "movie"
  }
}
