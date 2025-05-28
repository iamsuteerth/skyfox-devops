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
    ├── alb/             # Load balancers
    └── s3/              # Profile image storage
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

### 4. Two-Phase Deployment

**Phase 1: Deploy Infrastructure Only**
```bash
cd terraform
terraform init
terraform plan
terraform apply  # Deploys infrastructure without ECS services
```

**Phase 2: Build and Push Images**
```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin [account].dkr.ecr.ap-south-1.amazonaws.com

# Build ARM64 images
docker buildx build --platform linux/arm64 \
  --tag [account].dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-backend:latest \
  --push .
```

**Phase 3: Deploy Services**
```bash
terraform apply -var="deploy_services=true"  # Deploys ECS services after images are available
```

**Important**: Services require the `deploy_services=true` variable to ensure ECS services are only created after container images are pushed to ECR. This prevents service deployment failures due to missing images.

## Takeaways

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
- **Security group isolation**: Network boundaries maintained through security groups
- **ALB communication**: Internal ALB restricted to ECS instances while maintaining service isolation

### Frontend URL Management
- **Challenge**: ALB DNS names contain random identifiers that change on infrastructure recreation
- **Solution**: Environment variable injection in CI/CD pipeline to dynamically configure frontend URLs
- **Options**: Vercel environment variables, Parameter Store, or custom domain with Route 53
- **Learning**: Infrastructure URLs should be dynamic, not hardcoded in frontend applications

### Architecture Simplification Journey
- **Started with complex design**: Private subnets with placement constraints
- **Hit placement constraint deadlock**: Services couldn't find appropriate instances
- **Simplified to elegant solution**: All services in public subnets with security group isolation
- **Resource efficiency**: Single Auto Scaling Group instead of multiple dedicated groups

### Security & Operations
- **Parameter Store**: Secure secret management with runtime injection
- **Security groups**: Network isolation without subnet complexity
- **Cost optimization**: ARM64 instances and lifecycle policies
- **Environment variable management**: Separation of sensitive and non-sensitive config

### Key Problem Solved
**Placement Constraint Deadlock**: Initially designed with private subnets and complex placement constraints that prevented services from finding suitable instances. Simplified to public-only subnets with security group isolation, maintaining security while eliminating deployment complexity.

### Cost Optimization
- **AWS Free Tier**: t4g.small instances and resource right-sizing
- **No NAT Gateway**: Eliminated unnecessary networking costs
- **ECR lifecycle policies**: Automatic image cleanup
- **Resource sharing**: Single infrastructure serving multiple services

---
**Status**: Complete microservices platform with load balancing and storage - Ready for CI/CD integration with GoCD