resource "aws_ecs_task_definition" "payment" {
  family                   = "${var.project_name}-${var.environment}-payment"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  cpu    = var.payment_cpu     
  memory = var.payment_memory 

  container_definitions = jsonencode([
    {
      name      = "payment"
      image     = "${var.repository_urls["payment-service"]}:latest"
      cpu       = var.payment_cpu
      memory    = var.payment_memory
      essential = true

      portMappings = [
        {
          containerPort = var.payment_port  
          hostPort      = 0                 
          protocol      = "tcp"
        }
      ]

      # Environment variables
      environment = [
        {
          name  = "PORT"
          value = tostring(var.payment_port)
        },
        {
          name  = "GIN_MODE"
          value = "release"
        },
        {
          name  = "LOG_LEVEL"
          value = "info"
        },
        {
          name  = "APP_VERSION"
          value = "prod"
        }
      ]

      # Secret from Parameter Store
      secrets = [
        {
          name      = "API_KEY"
          valueFrom = "/skyfox-backend/payment-gateway-api-key"
        }
      ]

      healthCheck = {
        command = [
          "CMD-SHELL",
          "wget -qO- http://localhost:${var.payment_port}/pshealth || exit 1"
        ]
        interval    = 30
        retries     = 3
        startPeriod = 60
        timeout     = 5
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "payment"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-payment-task"
    Environment = var.environment
    Project     = var.project_name
    Service     = "payment"
  }
}

resource "aws_ecs_task_definition" "movie" {
  family                   = "${var.project_name}-${var.environment}-movie"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  cpu    = var.movie_cpu     
  memory = var.movie_memory  

  container_definitions = jsonencode([
    {
      name      = "movie"
      image     = "${var.repository_urls["movie-service"]}:latest"
      cpu       = var.movie_cpu
      memory    = var.movie_memory
      essential = true

      portMappings = [
        {
          containerPort = var.movie_port   
          hostPort      = 0                
          protocol      = "tcp"
        }
      ]

      # Environment variables
      environment = [
        {
          name  = "PORT"
          value = tostring(var.movie_port)
        },
        {
          name  = "GIN_MODE"
          value = "release"
        },
        {
          name  = "LOG_LEVEL"
          value = "info"
        },
        {
          name  = "APP_VERSION"
          value = "prod"
        },
        {
          name  = "MOVIES_DATA_PATH"
          value = "/app/data/movies.json"
        }
      ]

      # Secret from Parameter Store
      secrets = [
        {
          name      = "API_KEY"
          valueFrom = "/skyfox-backend/movie-service-api-key"
        }
      ]

      healthCheck = {
        command = [
          "CMD-SHELL",
          "wget -qO- http://localhost:${var.movie_port}/mshealth || exit 1"
        ]
        interval    = 30
        retries     = 3
        startPeriod = 60
        timeout     = 5
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "movie"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-movie-task"
    Environment = var.environment
    Project     = var.project_name
    Service     = "movie"
  }
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-${var.environment}-backend"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  cpu    = var.backend_cpu    
  memory = var.backend_memory 

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.repository_urls["backend"]}:latest"
      cpu       = var.backend_cpu
      memory    = var.backend_memory
      essential = true

      portMappings = [
        {
          containerPort = var.backend_port  
          hostPort      = 0                 
          protocol      = "tcp"
        }
      ]

      # Environment variables
      environment = [
        {
          name  = "PORT"
          value = tostring(var.backend_port)
        },
        {
          name  = "GIN_MODE" 
          value = "release"
        },
        {
          name  = "AWS_REGION"
          value = "ap-south-1"
        },
        {
          name  = "S3_BUCKET"
          value = var.s3_bucket_name
        },
        {
          name  = "MOVIE_SERVICE_URL"
          value = var.movie_service_url
        },
        {
          name  = "PAYMENT_GATEWAY_URL"
          value = var.payment_gateway_url
        }
      ]

      # Secrets from Parameter Store
      secrets = [
        {
          name      = "JWT_SECRET_KEY"
          valueFrom = "/skyfox-backend/jwt-secret"
        },
        {
          name      = "DATABASE_URL"
          valueFrom = "/skyfox-backend/database-url"
        },
        {
          name      = "MOVIE_SERVICE_API_KEY"
          valueFrom = "/skyfox-backend/movie-service-api-key"
        },
        {
          name      = "PAYMENT_GATEWAY_API_KEY"
          valueFrom = "/skyfox-backend/payment-gateway-api-key"
        },
        {
          name = "API_GATEWAY_KEY"
          valueFrom = "/skyfox-backend/api-gateway-key"
        }
      ]

      healthCheck = {
        command = [
          "CMD-SHELL",
          "wget -qO- http://localhost:${var.backend_port}/health || exit 1"
        ]
        interval    = 30
        retries     = 3
        startPeriod = 60
        timeout     = 5
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-task"
    Environment = var.environment
    Project     = var.project_name
    Service     = "backend"
  }
}