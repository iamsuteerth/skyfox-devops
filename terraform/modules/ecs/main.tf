# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Launch Template
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-${var.environment}-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.ecs_instance_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  # Defining the variable for usage in the shell script by the means of templating
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = aws_ecs_cluster.main.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-ecs-instance"
      Environment = var.environment
      Project     = var.project_name
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-launch-template"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-${var.environment}-ecs-asg"
  vpc_zone_identifier = concat(var.public_subnet_ids, var.private_subnet_ids)
  
  min_size         = var.min_capacity
  max_size         = var.max_capacity
  desired_capacity = var.desired_capacity
  
  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  health_check_type         = "EC2"  
  health_check_grace_period = 300    
  
  default_cooldown          = 300    
  termination_policies      = ["OldestInstance"]  
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-ecs-instance"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
  
  tag {
    key                 = "ECSCluster"
    value               = aws_ecs_cluster.main.name
    propagate_at_launch = true
  }
}