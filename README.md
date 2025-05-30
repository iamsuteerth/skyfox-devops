# SkyFox DevOps Infrastructure

**A production-grade microservices platform on AWS using Terraform and ECS with enterprise monitoring.**

## What I've Built

SkyFox is a movie platform backend with three services:
- **Backend Service** (8080): Main API with authentication and Supabase integration  
- **Payment Service** (8082): Transaction processing
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
- **Service placement**: Services distributed efficiently across instances
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
- **ADOT Sidecar Collectors**: Prometheus metrics collection and forwarding
- **API Performance Monitoring**: Request rates, response times, error tracking by endpoint groups
- **EFS Configuration Management**: Centralized ADOT configuration storage
- **Unique Instance Labeling**: Deployment tracking and metadata

## Repository Structure

```
terraform/
├── main.tf                # Module orchestration
├── outputs.tf             # Infrastructure URLs and configs
├── variables.tf           # Global settings
└── modules/
    ├── networking/        # VPC, subnets, security groups
    ├── ecr/               # Docker repositories  
    ├── ecs/               # Container platform
    │   ├── asg.tf         # Auto scaling configuration
    │   ├── services.tf    # ECS service definitions
    │   ├── tasks.tf       # Task definitions
    │   └── adot-config.tf # ADOT monitoring configuration
    ├── alb/               # Load balancers
    ├── s3/                # Profile image storage
    └── prometheus/        # AWS Managed Prometheus workspace
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

```bash
bucket = "skyfox-devprod-profile-images-your-unique-suffix"
```

### 4. Phased Deployment Strategy

**Phase 1: Infrastructure Only**
```bash
cd terraform
terraform init
terraform plan
terraform apply  # Deploys VPC, ALB, ECR, S3, AMP without ECS services
```

**Phase 2: Build and Push Container Images**
```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin [account].dkr.ecr.ap-south-1.amazonaws.com

# Build and push ARM64 images with version tags
docker buildx build --platform linux/arm64 \
  --tag [account].dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-backend:latest \
  --tag [account].dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-backend:prometheus-v1 \
  --push .

# Repeat for payment and movie services
```

**Phase 3: Launch ECS Services with Auto Scaling**
```bash
terraform apply -var="deploy_services=true" -var="enable_auto_scaling=true"
```

### 5. Advanced Deployment Control

**Per-Service Image Deployment:**
```bash
# Update only backend service
terraform apply -var="deploy_services=true" -var="enable_auto_scaling=true" -var="backend_image_tag=prometheus-v1"

# Update multiple services with different versions
terraform apply \
  -var="deploy_services=true" \
  -var="enable_auto_scaling=true" \
  -var="backend_image_tag=prometheus-v1" \
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
  -var="backend_image_tag=prometheus-v1" \
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
-var="backend_image_tag=prometheus-v1"
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
- **Scale In**: When CPU < 70% AND Memory < 80%
- **Range**: 2-3-4 tasks per service

### Instance-Level Scaling
- **Scale Out**: When cluster memory reservation > 80%
- **Scale In**: When cluster memory reservation < 30%
- **Range**: 2-4 EC2 instances (t4g.small ARM64)

### Complete Auto Scaling Flow
**The infrastructure handles these scenarios:**
1. **Container resource pressure** → Service scaling creates new containers
2. **Instance capacity constraints** → Cluster scaling adds new EC2 instances
3. **Low utilization periods** → Automatic scale-down for cost optimization
4. **Protection mechanisms** → Min/max limits and cooldown periods prevent instability

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
- **Rollback Protection**: Automatic rollback if deployment fails

## Monitoring & Observability Architecture

### AWS Managed Prometheus Integration
**Managed metrics collection and storage:**
- **AMP Workspace**: Scalable, managed Prometheus storage
- **ADOT Sidecar Pattern**: Distributed collection with auto-scaling
- **IAM Authentication**: Secure metrics ingestion with AWS SigV4
- **Cost Optimization**: Pay-per-metric ingestion model

### ADOT (AWS Distro for OpenTelemetry) Configuration
**Sidecar collector deployment:**
```yaml
# Each backend task contains:
- Backend Container (port 8080)
- ADOT Collector Sidecar (scrapes backend:8080/metrics)
```

**Monitoring capabilities:**
- **API Performance**: Request rates, response times, error tracking
- **Endpoint Grouping**: Logical categorization (auth, booking, wallet, shows)
- **Instance Tracking**: Unique deployment identification
- **Automatic Scaling**: Collectors scale with backend tasks

### Metrics Collection Strategy
**Backend API metrics grouped by business function:**
- **auth**: Login, security questions, password management
- **customer_mgmt**: Profile management and signup
- **wallet**: Payment and transaction operations  
- **booking**: Reservation and ticket management
- **shows**: Movie catalog and scheduling
- **admin**: Administrative operations
- **checkin**: Staff check-in operations

**Key metrics collected:**
```
skyfox_http_requests_total{method, endpoint_group, status_code}
skyfox_http_request_duration_seconds{method, endpoint_group}
skyfox_http_requests_in_flight
```

### ADOT Sidecar Networking Solution
**ECS Bridge Networking:**
- **Problem**: Container dynamic ports (32768, 32769) not accessible via localhost:8080
- **Solution**: Containers in same ECS task share network namespace
- **Implementation**: ADOT scrapes `backend:8080` (container name + internal port)
- **Scaling**: Each backend task gets its own ADOT collector (perfect isolation)

## Technical Learnings & Solutions

### Terraform Patterns
- **Module organization**: Clean separation of networking, compute, and storage
- **Template variables**: Using `templatefile()` for dynamic user data scripts
- **Resource dependencies**: Proper ordering to avoid circular dependencies
- **ARM64 optimization**: Cost-effective compute with ECS-optimized AMI

### AWS Container Architecture
- **ECS cluster design**: Single Auto Scaling Group serving all services
- **ALB path-based routing**: Service discovery without service mesh complexity
- **Multi-AZ deployment**: High availability across availability zones
- **IAM role separation**: Instance vs task vs execution roles

### Security Group Architecture
- **Initial complexity**: Service-specific security groups created circular dependencies
- **Solution**: Use `aws_security_group_rule` resources instead of inline rules
- **Final architecture**: 3 security groups (External ALB, Internal ALB, ECS Instances) with proper isolation
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
- **Rollback protection**: Automatic rollback protection for failed deployments
- **Fine-grained control**: Deploy services independently with different versions

### Frontend URL Management
- **Challenge**: ALB DNS names contain random identifiers that change on infrastructure recreation
- **Solution**: Environment variable injection to configure frontend's backend configuration
- **Options**: Vercel environment variables, Parameter Store, or custom domain with Route 53
- **Learning**: Infrastructure URLs should be dynamic, not hardcoded in frontend applications

### Architecture Evolution
- **Started with**: Complex design using private subnets with placement constraints
- **Hit roadblock**: Placement constraint deadlock prevented services from finding appropriate instances
- **Final solution**: All services in public subnets with security group isolation
- **Result**: Maintained security while eliminating deployment complexity and improving resource efficiency

### Critical ECS Networking Discoveries
**Task-Level Network Isolation:**
- **Key insight**: Containers within same ECS task share Docker bridge network
- **Communication method**: Use container names + internal ports (`backend:8080`)
- **Scaling behavior**: Multiple backend tasks on same instance = isolated networks per task
- **ADOT implementation**: Each sidecar only sees its task's containers
- **Industry standard**: Approach used by Netflix, Uber, AWS internal services

**Bridge Networking Details:**
- **Container ports vs host ports**: Internal (8080) vs dynamic external (32768+)
- **Localhost limitation**: `localhost:8080` not accessible from host or other containers
- **Sidecar advantage**: Perfect for intra-task communication without service discovery
- **Multiple instance handling**: Task network isolation prevents cross-task interference

### ADOT Configuration Management
- **Template variables**: Resolved by Terraform at deployment time (`${ecs_cluster_name}`)
- **Configuration storage**: EFS for shared access, Parameter Store for sensitive data
- **Unique instance labeling**: Random deployment IDs for tracking and debugging

### Key Problems Solved
- **Placement Constraint Deadlock**: Simplified from private subnets with complex constraints to public subnets with security group isolation, maintaining security while eliminating deployment complexity
- **ADOT Sidecar Networking**: Solved container-to-container communication within ECS tasks using bridge networking and container name resolution, enabling scalable monitoring without service discovery

### Cost Optimization
- **AWS Free Tier**: t4g.small instances and resource right-sizing
- **No NAT Gateway**: Eliminated unnecessary networking costs
- **ECR lifecycle policies**: Automatic image cleanup
- **Resource sharing**: Single infrastructure serving multiple services
- **Efficient monitoring**: Sidecar pattern vs central Prometheus server

