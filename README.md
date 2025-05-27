# SkyFox DevOps Infrastructure

## Overview

This repository contains the infrastructure as code (IaC) for the SkyFox project - a microservices-based application demonstrating enterprise-grade DevOps practices. The infrastructure is provisioned using Terraform and deployed on AWS, featuring a complete container orchestration platform with intelligent load balancing and security architecture.

## Architecture

The SkyFox backend consists of three components:
- **Backend Service** (Port 8080): Main application backend with Supabase connectivity
- **Payment Service** (Port 8082): Handles payment processing (internal only)
- **Movie Service** (Port 4567): Manages movie-related functionality (internal only)

### Production Traffic Flow Architecture

```
Internet → External ALB → Backend Service (Public Subnet)
                       ↓
Backend Service → Internal ALB → /payment-service/* → Payment Service (Private Subnet)
                               → /movie-service/*   → Movie Service (Private Subnet)
```

**Frontend Integration:**
- Frontend communicates exclusively with Backend Service via External ALB
- All API calls use `/` endpoint on Backend Service
- Backend orchestrates internal service communication

**Service-to-Service Communication:**
- Backend Service calls: `http://internal-alb/payment-service/payment-service`
- Backend Service calls: `http://internal-alb/movie-service/movies-service`
- Internal ALB provides path-based routing, load balancing, and health monitoring

### Advanced Network Segmentation

**Public Subnets (Internet Access):**
- External ALB (internet-facing load balancer)
- Backend Service instances (require Supabase connectivity)

**Private Subnets (No Internet Access):**
- Internal ALB (service-to-service load balancing)
- Payment and Movie Service instances (completely isolated)

**Mixed Subnet Strategy:**
- Single Auto Scaling Group spans both public and private subnets
- ECS placement constraints ensure services run on appropriate instances
- Resource efficiency through intelligent instance utilization

## Repository Structure

```
skyfox-devops/
├── terraform/               # Infrastructure as Code
│   ├── backend.tf           # S3 + DynamoDB remote state
│   ├── providers.tf         # AWS provider configuration
│   ├── terraform.tf         # Version requirements
│   ├── main.tf              # Module orchestration
│   ├── variables.tf         # Global variables
│   ├── outputs.tf           # Root outputs (URLs, ARNs, environment configs)
│   └── modules/
│       ├── networking/      # VPC, subnets, security groups
│       │   ├── network.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       ├── ecr/             # Docker repositories
│       │   ├── main.tf
│       │   ├── outputs.tf
│       │   └── variables.tf
│       ├── ecs/             # Container orchestration
│       │   ├── main.tf      # Cluster, launch template, ASG
│       │   ├── iam.tf       # Instance, execution, and task roles
│       │   ├── user_data.sh # Automatic cluster registration
│       │   ├── outputs.tf
│       │   └── variables.tf
│       └── alb/             # Load balancers
│           ├── main.tf      # External + internal ALBs
│           ├── outputs.tf   # Service URLs and target groups
│           └── variables.tf
└── gocd/                    # CI/CD pipelines (in future)
```

## Infrastructure Components

### Multi-AZ Networking Infrastructure

**VPC Design:**
- **CIDR**: `10.0.0.0/16` across 3 availability zones for high availability
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`
- **Private Subnets**: `10.0.10.0/24`, `10.0.20.0/24`, `10.0.30.0/24`

**Security Group Architecture:**
- **External ALB SG**: HTTP from internet (0.0.0.0/0:80)
- **Internal ALB SG**: HTTP only from backend service instances
- **Backend Service SG**: Port 8080 from external ALB + full internet egress
- **Payment/Movie SGs**: Only accept traffic from internal ALB + VPC-only egress
- **ECS Instance SG**: Container communication + SSH access

**Cost Optimization:**
- No NAT Gateway (private subnets truly isolated)
- Internet Gateway only for public subnet internet access

### Container Registry (ECR)
Production-ready Docker repositories with security and cost controls:

**Repository Configuration:**
- **3 Repositories**: `skyfox-devprod-backend`, `skyfox-devprod-payment-service`, `skyfox-devprod-movie-service`
- **Security**: Vulnerability scanning enabled, AES256 encryption at rest
- **Cost Management**: Lifecycle policies retain 4 tagged images, cleanup after 3 days
- **CI/CD Integration**: Repository URLs exported for automated deployments

### Container Orchestration (ECS)

**Compute Architecture:**
- **Mixed Subnet Auto Scaling Group**: EC2 instances distributed across public and private subnets
- **Smart Placement**: ECS placement constraints route services to appropriate network zones
- **Resource Efficiency**: Single ASG (2-4 t4g.small instances) serves all services
- **ARM64 Optimization**: Cost-effective t4g.small instances with ECS-optimized AMI

**IAM Security Model:**
- **Instance Role**: EC2 instances join ECS cluster, communicate with AWS APIs
- **Task Execution Role**: ECS pulls ECR images, manages container lifecycle, writes CloudWatch logs
- **Task Role**: Applications access AWS services (S3 for backend file operations)

**Container Foundation:**
- **ECS Cluster**: Container orchestration with Container Insights monitoring enabled
- **Launch Template**: ARM64 ECS-optimized AMI with automatic cluster registration
- **User Data Script**: Dynamic cluster name injection using Terraform templating
- **Auto Scaling**: Intelligent capacity management (2-4 instances based on demand)

### Load Balancing Infrastructure (ALB)
Dual-tier load balancing with path-based service routing:

**External Application Load Balancer:**
- **Purpose**: Internet-facing load balancer for frontend traffic
- **Configuration**: HTTP:80, spans all public subnets across 3 AZs
- **Target**: Backend service instances with `/health` endpoint monitoring
- **Security**: External ALB security group allows internet access

**Internal Application Load Balancer:**
- **Purpose**: Service-to-service communication within private network
- **Configuration**: Internal-only, spans all private subnets
- **Path-Based Routing**:
  - `/payment-service/*` → Payment Service instances (`/pshealth` monitoring)
  - `/movie-service/*` → Movie Service instances (`/mshealth` monitoring)
- **Default Action**: 404 response for unknown paths

**Health Check Strategy:**
- **Backend**: `/health` endpoint (30s interval, 200 OK expected)
- **Payment**: `/pshealth` endpoint (30s interval, 200 OK expected)
- **Movie**: `/mshealth` endpoint (30s interval, 200 OK expected)
- **Deregistration**: 30s delay for graceful shutdowns

## Learning Highlights

### Terraform Engineering Patterns
**Template Variables and Dependencies:**
- Dynamic user data generation using `templatefile()` function with cluster name injection
- Circular dependency resolution through proper resource ordering (cluster before launch template)
- ARM64 architecture optimization for cost-effective compute (t4g.small + ARM64 containers)

**Multi-Subnet Resource Strategies:**
- Single Auto Scaling Group spanning multiple subnet types for resource efficiency
- ECS placement constraints enable service-specific subnet targeting without resource waste
- Mixed subnet approach reduces infrastructure costs by 50% vs dedicated ASGs

**IAM Role Architecture:**
- Clear separation: instance-level vs container-level vs application-level permissions
- Task execution (platform operations) vs task runtime (application operations) role distinction
- Least-privilege security through role-specific, service-specific policies

### Infrastructure Design Patterns
**Advanced Security Architecture:**
- Network segmentation without over-provisioning resources
- Security group layering implementing defense-in-depth principles
- Public/private subnet isolation with selective, service-specific internet access

**Cost Optimization Strategies:**
- AWS Free Tier resource maximization (ALB, ECS, t4g.small instances)
- ECR lifecycle policies preventing storage cost drift
- Resource consolidation through intelligent placement and mixed subnet strategies

**Enterprise Scalability Foundations:**
- Multi-AZ high availability with automatic failover capabilities
- Auto Scaling Group integration ready for ECS capacity providers
- Modular Terraform design enabling independent component scaling and environments

**Load Balancing Intelligence:**
- Path-based routing solving service URL complexity without custom DNS
- Health check orchestration ensuring service reliability
- Target group management for blue-green deployments

### Container Orchestration Insights
**Service Discovery and Communication:**
- ALB-based service discovery eliminating complex service mesh requirements
- Environment variable injection for service URL configuration
- Path prefix handling in application code for ALB compatibility

**Resource Planning and Allocation:**
- Precise CPU and memory allocation (backend: 475/819, payment: 230/410, movie: 230/410)
- Capacity planning ensuring 55% resource headroom for ECS agent and scaling
- Mixed instance placement maximizing resource utilization efficiency

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Docker for local development and container building

## Deployment Guide

### Step 1: Remote State Infrastructure
```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket skyfox-terraform-state \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning for state history
aws s3api put-bucket-versioning \
  --bucket skyfox-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name skyfox-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### Step 2: Container Image Preparation
```bash
# Build and push backend service
docker buildx build --platform linux/arm64 \
  --tag [].dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-backend:latest \
  --push .

# Build and push payment service
docker buildx build --platform linux/arm64 \
  --tag [].dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-payment-service:latest \
  --push .

# Build and push movie service  
docker buildx build --platform linux/arm64 \
  --tag [].dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-movie-service:latest \
  --push .
```

### Step 3: Infrastructure Deployment
```bash
cd terraform

# Initialize Terraform with remote state
terraform init

# Review infrastructure plan
terraform plan

# Deploy complete infrastructure
terraform apply
```

### Step 4: Deployment Verification
```bash
# Verify ECS cluster and instances
aws ecs describe-clusters --clusters skyfox-devprod-cluster
aws ecs list-container-instances --cluster skyfox-devprod-cluster

# Verify Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names skyfox-devprod-ecs-asg

# Test load balancer endpoints
curl http://$(terraform output -raw external_alb_dns_name)/health
```