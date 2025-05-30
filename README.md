# SkyFox DevOps Infrastructure

**A complete microservices platform on AWS using Terraform and ECS.**

## What We Built

SkyFox is a movie platform backend with three services:
- **Backend Service** (8080): Main API with user auth and Supabase integration  
- **Payment Service** (8082): Handles transactions
- **Movie Service** (4567): Movie catalog management

## Architecture

```
Internet → External ALB → Backend Service
                       ↓
Backend Service → Internal ALB → /payment-service/* → Payment Service
                               → /movie-service/*   → Movie Service
```

**Traffic Flow:**
- Frontend hits External ALB → Backend Service (public subnet)
- Backend calls Internal ALB → Payment/Movie Services (public subnet)
- Path-based routing: `/payment-service/*` and `/movie-service/*`

## Infrastructure Components

### Network Design
- **VPC**: `10.0.0.0/16` across 3 availability zones
- **Public subnets only**: All services with internet access for simplicity
- **Security groups**: Layered access control between services

### Container Platform
- **ECS Cluster**: 2-4 t4g.small ARM64 instances
- **Single Auto Scaling Group**: All instances in public subnets
- **Smart service placement**: Services run correctly without complex constraints
- **ECR repositories**: Automated image lifecycle management

### Load Balancing
- **External ALB**: Internet-facing, routes to backend
- **Internal ALB**: Service-to-service communication with path routing
- **Health checks**: `/health`, `/pshealth`, `/mshealth` endpoints

### Storage & Secrets
- **S3 bucket**: Profile image storage with encryption
- **Parameter Store**: JWT secrets, API keys, database URLs
- **IAM roles**: Least-privilege access for each service

### Monitoring & Observability
- **AWS Managed Prometheus**: Scalable metrics storage and querying
- **Prometheus metrics**: API performance monitoring with endpoint grouping
- **Parameter Store integration**: AMP workspace discovery for ADOT collectors

## Repository Structure

```
terraform/
├── main.tf              # Module orchestration
├── outputs.tf           # Infrastructure URLs and configs
├── variables.tf         # Global settings
└── modules/
    ├── networking/      # VPC, subnets, security groups
    ├── ecr/             # Docker repositories  
    ├── ecs/             # Container platform
    │   ├── asg.tf       # Auto scaling configuration
    │   ├── services.tf  # ECS service definitions
    │   └── tasks.tf     # Task definitions
    ├── alb/             # Load balancers
    ├── s3/              # Profile image storage
    └── prometheus/      # AWS Managed Prometheus workspace
```

## Deployment

### Prerequisites
```bash
# AWS CLI configured
# Terraform >= 1.0
# Docker for building images
```

### 1. Remote State Setup
```bash
aws s3api create-bucket \
  --bucket skyfox-terraform-state \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning \
  --bucket skyfox-terraform-state \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name skyfox-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. Store Environment Variables
```bash
aws ssm put-parameter --name "/skyfox-backend/jwt-secret" --value "your-jwt-secret" --type "SecureString"
aws ssm put-parameter --name "/skyfox-backend/database-url" --value "your-supabase-url" --type "SecureString"
aws ssm put-parameter --name "/skyfox-backend/movie-service-api-key" --value "your-key" --type "SecureString"
aws ssm put-parameter --name "/skyfox-backend/payment-gateway-api-key" --value "your-key" --type "SecureString"
aws ssm put-parameter --name "/skyfox-backend/s3-bucket" --value "bucket-name" --type "SecureString"
aws ssm put-parameter --name "/skyfox-backend/api-gateway-key" --value "your-api-gateway-key-value" --type "SecureString"
```

### 3. S3 Bucket Configuration
**Important**: The S3 bucket name `skyfox-devprod-profile-images` might be taken globally. If deployment fails, update the bucket name in `modules/s3/main.tf`:

```hcl
bucket = "skyfox-devprod-profile-images-your-unique-suffix"
```

### 4. Controlled Deployment Strategy

**Phase 1: Infrastructure Only**
```bash
cd terraform
terraform init
terraform plan
terraform apply  # Deploys VPC, ALB, ECR, S3, AMP without ECS services and ASG
```

**Phase 2: Build and Push Container Images**
```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin [account].dkr.ecr.ap-south-1.amazonaws.com

# Build and push ARM64 images with version tags
docker buildx build --platform linux/arm64 \
  --tag [account].dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-backend:latest \
  --tag [account].dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-backend:v1.0 \
  --push .

# Repeat for payment and movie services
```

**Phase 3: Launch ECS Services with Auto Scaling (Production Ready)**
```bash
terraform apply -var="deploy_services=true" -var="enable_auto_scaling=true"
```

### 5. Advanced Deployment Control

**Per-Service Image Deployment:**
```bash
# Update only backend service
terraform apply -var="deploy_services=true" -var="enable_auto_scaling=true" -var="backend_image_tag=v2.1.0"

# Update multiple services with different versions
terraform apply \
  -var="deploy_services=true" \
  -var="enable_auto_scaling=true" \
  -var="backend_image_tag=v2.1.0" \
  -var="payment_image_tag=v1.5.2"

# Mixed development deployment
terraform apply \
  -var="deploy_services=true" \
  -var="enable_auto_scaling=true" \
  -var="backend_image_tag=dev-build-123" \
  -var="payment_image_tag=v1.0.0" \
  -var="movie_image_tag=v1.0.0"
```

**Per-Service Force Deployment:**
```bash
# Force restart only backend service
terraform apply -var="deploy_services=true" -var="enable_auto_scaling=true" -var="force_backend_deployment=true"

# Force restart specific service with new image
terraform apply \
  -var="deploy_services=true" \ 
  -var="enable_auto_scaling=true" \
  -var="backend_image_tag=v2.0.0" \
  -var="force_backend_deployment=true"

# Emergency restart of all services
terraform apply -var="deploy_services=true" -var="enable_auto_scaling=true" -var="force_deployment=true"
```

**Available deployment variables:**
```bash
# Infrastructure only
terraform apply

# Services without auto scaling
terraform apply -var="deploy_services=true"

# Services with auto scaling
terraform apply -var="deploy_services=true" -var="enable_auto_scaling=true"

# Per-service image control
-var="backend_image_tag=v1.1"
-var="payment_image_tag=v1.2"
-var="movie_image_tag=v1.3"

# Per-service force deployment
-var="force_backend_deployment=true"
-var="force_payment_deployment=true"
-var="force_movie_deployment=true"
```

**Important**: Services require the `deploy_services=true` variable to ensure ECS services are only created after container images are pushed to ECR. This prevents service deployment failures due to missing images.

## Auto Scaling Configuration

### Service-Level Scaling
**CPU and Memory Based:**
- **Scale Out**: When CPU > 70% OR Memory > 80%
- **Scale In**: When CPU  80%
- **Scale In**: When cluster memory reservation < 30%
- **Range**: 2-4 EC2 instances (t4g.small ARM64)

### Deployment Strategy
**Resource-Aware Rolling Updates:**
```bash
deployment_maximum_percent         = 100  # Never exceed desired count
deployment_minimum_healthy_percent = 50   # Allow 50% capacity during updates
```

**Why 100/50 Strategy:**
- **Resource Constrained**: 2 t4g.small instances with limited capacity
- **Cost Efficient**: No temporary over-provisioning during updates
- **Acceptable Trade-off**: Brief 50% capacity reduction vs infrastructure costs
- **Circuit Breaker Protection**: Automatic rollback if deployment fails

## What We Learned

### Terraform Patterns
- **Module organization**: Clean separation of networking, compute, and storage
- **Template variables**: Using `templatefile()` for dynamic user data scripts
- **Resource dependencies**: Proper ordering to avoid circular dependencies
- **ARM64 optimization**: Cost-effective compute with ECS-optimized AMI

### AWS Container Architecture
- **ECS cluster design**: Single Auto Scaling Group serving all services
- **ALB path-based routing**: Service discovery without complex service mesh
- **Multi-AZ deployment**: High availability across availability zones
- **IAM role separation**: Instance vs task vs execution roles

### Security Group Architecture
- **Complex service-specific security groups**: Created circular dependencies preventing deployment
- **Circular dependency solution**: Use `aws_security_group_rule` resources instead of inline rules
- **Simplified architecture**: 3 security groups (External ALB, Internal ALB, ECS Instances) with proper isolation
- **Dynamic port ranges**: Required for ALB communication with ECS containers (32768-65535)

### Container Health Monitoring
- **Health check standardization**: All services use `wget` commands for container health checks
- **Tool availability**: Health check commands must match tools available inside container images
- **ECS vs ALB health checks**: Different health check mechanisms serve different purposes

### Network Security & Access
- **ECS internet access**: Required for AWS services (ECR, Parameter Store, CloudWatch)
- **Security group isolation**: Network boundaries maintained through security groups, not subnet complexity
- **ALB communication**: Internal ALB restricted to ECS instances while maintaining service isolation

### Service Update & Deployment Management
- **Per-service image tags**: Independent versioning for each service (backend, payment, movie)
- **Per-service force deployment**: Individual service restart capability  
- **SHA-based auto-deployment**: Automatic updates when task definitions change
- **Circuit breakers**: Automatic rollback protection for failed deployments
- **Fine-grained control**: Deploy services independently with different versions

### Frontend URL Management
- **Challenge**: ALB DNS names contain random identifiers that change on infrastructure recreation
- **Solution**: Environment variable injection to configure frontend's backend configuration
- **Options**: Vercel environment variables, Parameter Store, or custom domain with Route 53
- **Learning**: Infrastructure URLs should be dynamic, not hardcoded in frontend applications

### Architecture Simplification Journey
- **Started with complex design**: Private subnets with placement constraints
- **Hit placement constraint deadlock**: Services couldn't find appropriate instances
- **Simplified to elegant solution**: All services in public subnets with security group isolation
- **Resource efficiency**: Single Auto Scaling Group instead of multiple dedicated groups

### Production Readiness Considerations
- **Circuit Breakers**: Prevent bad deployments from affecting healthy services
- **Auto Scaling**: Both service-level and instance-level scaling implemented
- **Monitoring**: CloudWatch logging enabled, Container Insights activated
- **Cost Optimization**: ARM64 instances, lifecycle policies, and resource right-sizing
- **Deployment flexibility**: Per-service versioning and rolling update strategies

### Security & Operations
- **Parameter Store**: Secure secret management with runtime injection
- **Security groups**: Network isolation without subnet complexity
- **Cost optimization**: ARM64 instances and lifecycle policies
- **Environment variable management**: Separation of sensitive and non-sensitive config
- **Operational excellence**: Fine-grained deployment control for debugging and maintenance

### Key Problem Solved
**Placement Constraint Deadlock**: Initially designed with private subnets and complex placement constraints that prevented services from finding suitable instances. Simplified to public-only subnets with security group isolation, maintaining security while eliminating deployment complexity.

### Cost Optimization
- **AWS Free Tier**: t4g.small instances and resource right-sizing
- **No NAT Gateway**: Eliminated unnecessary networking costs
- **ECR lifecycle policies**: Automatic image cleanup
- **Resource sharing**: Single infrastructure serving multiple services

---
**Status**: Production-grade microservices platform with auto scaling, circuit breakers, per-service deployment control, and observability foundation - Complete infrastructure ready for advanced monitoring and application development.
