resource "aws_appautoscaling_target" "backend" {
  count = var.deploy_services && var.enable_auto_scaling ? 1 : 0

  max_capacity       = var.backend_max_capacity
  min_capacity       = var.backend_desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.backend]

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-autoscaling"
    Environment = var.environment
    Project     = var.project_name
    Service     = "backend"
  }
}

resource "aws_appautoscaling_target" "payment" {
  count = var.deploy_services && var.enable_auto_scaling ? 1 : 0

  max_capacity       = var.payment_max_capacity
  min_capacity       = var.payment_desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.payment[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.payment]

  tags = {
    Name        = "${var.project_name}-${var.environment}-payment-autoscaling"
    Environment = var.environment
    Project     = var.project_name
    Service     = "payment"
  }
}

resource "aws_appautoscaling_target" "movie" {
  count = var.deploy_services && var.enable_auto_scaling ? 1 : 0

  max_capacity       = var.movie_max_capacity
  min_capacity       = var.movie_desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.movie[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.movie]

  tags = {
    Name        = "${var.project_name}-${var.environment}-movie-autoscaling"
    Environment = var.environment
    Project     = var.project_name
    Service     = "movie"
  }
}

# CPU-based scaling policies
resource "aws_appautoscaling_policy" "backend_scale_up_cpu" {
  count = var.deploy_services && var.enable_auto_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-backend-scale-up-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.backend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.backend_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "payment_scale_up_cpu" {
  count = var.deploy_services && var.enable_auto_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-payment-scale-up-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.payment[0].resource_id
  scalable_dimension = aws_appautoscaling_target.payment[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.payment[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.payment_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "movie_scale_up_cpu" {
  count = var.deploy_services && var.enable_auto_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-movie-scale-up-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.movie[0].resource_id
  scalable_dimension = aws_appautoscaling_target.movie[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.movie[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.movie_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Memory-based scaling policies
resource "aws_appautoscaling_policy" "backend_scale_up_memory" {
  count = var.deploy_services && var.enable_auto_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-backend-scale-up-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.backend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.backend_memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "payment_scale_up_memory" {
  count = var.deploy_services && var.enable_auto_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-payment-scale-up-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.payment[0].resource_id
  scalable_dimension = aws_appautoscaling_target.payment[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.payment[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.payment_memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "movie_scale_up_memory" {
  count = var.deploy_services && var.enable_auto_scaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-movie-scale-up-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.movie[0].resource_id
  scalable_dimension = aws_appautoscaling_target.movie[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.movie[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.movie_memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Auto Scaling Group scaling policies
resource "aws_autoscaling_policy" "ecs_scale_out" {
  count = var.enable_auto_scaling ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-ecs-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.ecs.name
}

resource "aws_autoscaling_policy" "ecs_scale_in" {
  count = var.enable_auto_scaling ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-ecs-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.ecs.name
}

resource "aws_cloudwatch_metric_alarm" "ecs_capacity_high" {
  count = var.enable_auto_scaling ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-capacity-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS cluster memory reservation"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }

  alarm_actions = [aws_autoscaling_policy.ecs_scale_out[0].arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-capacity-high-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_capacity_low" {
  count = var.enable_auto_scaling ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-ecs-capacity-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors ECS cluster memory reservation"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }

  alarm_actions = [aws_autoscaling_policy.ecs_scale_in[0].arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-capacity-low-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}
