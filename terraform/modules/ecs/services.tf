resource "aws_ecs_service" "backend" {
  count = var.deploy_services ? 1 : 0

  name            = "${var.project_name}-${var.environment}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count

  launch_type = "EC2"

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = var.backend_port
  }

  triggers = {
    redeployment = sha1(jsonencode(aws_ecs_task_definition.backend.revision))
  }
  
  force_new_deployment = var.force_deployment

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds  = 300
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50

  depends_on = [var.backend_target_group_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-service"
    Environment = var.environment
    Project     = var.project_name
    Service     = "backend"
  }
}

resource "aws_ecs_service" "payment" {
  count = var.deploy_services ? 1 : 0

  name            = "${var.project_name}-${var.environment}-payment"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = var.payment_desired_count

  launch_type = "EC2"

  load_balancer {
    target_group_arn = var.payment_target_group_arn
    container_name   = "payment"
    container_port   = var.payment_port
  }

  triggers = {
    redeployment = sha1(jsonencode(aws_ecs_task_definition.payment.revision))
  }
  
  force_new_deployment = var.force_deployment

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds  = 300
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50

  depends_on = [var.payment_target_group_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-payment-service"
    Environment = var.environment
    Project     = var.project_name
    Service     = "payment"
  }
}

resource "aws_ecs_service" "movie" {
  count = var.deploy_services ? 1 : 0

  name            = "${var.project_name}-${var.environment}-movie"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.movie.arn
  desired_count   = var.movie_desired_count

  launch_type = "EC2"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  triggers = {
    redeployment = sha1(jsonencode(aws_ecs_task_definition.movie.revision))
  }
  
  force_new_deployment = var.force_deployment

  load_balancer {
    target_group_arn = var.movie_target_group_arn
    container_name   = "movie"
    container_port   = var.movie_port
  }

  health_check_grace_period_seconds  = 300
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50

  depends_on = [var.movie_target_group_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-movie-service"
    Environment = var.environment
    Project     = var.project_name
    Service     = "movie"
  }
}
