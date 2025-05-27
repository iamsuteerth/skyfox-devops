# SkyFox DevOps Infrastructure

## Overview

This repository contains the infrastructure as code (IaC) for the SkyFox project. The infrastructure is provisioned using Terraform and deployed on AWS.

## Architecture

The SkyFox backend consists of three components:
- **Backend Service** (Port 8080): Main application backend with Supabase connectivity
- **Payment Service** (Port 8082): Handles payment processing (internal only)
- **Movie Service** (Port 4567): Manages movie-related functionality (internal only)

### Traffic Flow Architecture

```
Internet → External ALB → Backend Service (Public Subnet)
                       ↓
Backend Service → Internal ALB → Payment Service (Private Subnet)
                               → Movie Service (Private Subnet)
```

**Frontend Communication:**
- Frontend only communicates with Backend Service via External ALB
- All API calls go to `/api` endpoints on Backend Service

**Backend-to-Services Communication:**
- Backend Service orchestrates calls to Payment and Movie services
- Internal ALB provides load balancing and health checking for internal services
- Path-based routing: `/payment` → Payment Service, `/movie` → Movie Service

### Network Segmentation

**Public Subnets:**
- External ALB (internet-facing)
- Backend Service (needs Supabase connectivity)

**Private Subnets:**
- Internal ALB
- Payment and Movie Services (no direct internet access)

## Repository Structure

```
skyfox-devops/
├── terraform/               # Infrastructure as Code
│   ├── backend.tf           # Remote state configuration
│   ├── providers.tf         # AWS provider setup
│   ├── terraform.tf         # Version requirements
│   ├── main.tf              # Module orchestration
│   ├── variables.tf         # Global variables
│   ├── outputs.tf           # Root outputs
│   └── modules/
│       ├── networking/      # VPC, subnets, security groups
│       ├── ecr/             # Docker repositories
│       ├── ecs/             # Container orchestration
│       └── alb/             # Load balancers (planned)
└── gocd/                    # CI/CD pipelines (planned)
```

## Infrastructure Components

### Networking Infrastructure
Multi-AZ VPC setup with security group architecture:
- **VPC**: `10.0.0.0/16` across 3 availability zones
- **Public Subnets**: External ALB and Backend Service placement
- **Private Subnets**: Internal ALB and Payment/Movie service placement
- **Security Groups**: Layered security with least-privilege access patterns

```
ap-south-1a: 10.0.1.0/24 (public) + 10.0.10.0/24 (private)
ap-south-1b: 10.0.2.0/24 (public) + 10.0.20.0/24 (private)  
ap-south-1c: 10.0.3.0/24 (public) + 10.0.30.0/24 (private)
```

### Container Registry (ECR)
Docker repositories for microservices:
- **3 Repositories**: backend, payment-service, movie-service
- **Security**: Vulnerability scanning enabled, AES256 encryption
- **Cost Optimization**: Lifecycle policies (keep 4 images, cleanup after 3 days)
- **Integration**: Repository URLs exported for container deployment

### Container Orchestration (ECS)
Container platform with intelligent resource management:

**Compute Strategy:**
- **Mixed Subnet Auto Scaling Group**: EC2 instances span both public and private subnets
- **Smart Placement**: ECS placement constraints route services to appropriate subnet instances
- **Resource Efficiency**: Single ASG serves all services, maximizing t4g.small capacity utilization

**IAM Architecture:**
- **Instance Role**: EC2 instances join ECS cluster and communicate with AWS APIs
- **Task Execution Role**: ECS pulls container images from ECR and manages container lifecycle
- **Task Role**: Applications access AWS services (S3 for backend Supabase integration)

**Container Foundation:**
- **ECS Cluster**: Container orchestration with Container Insights monitoring
- **Launch Template**: ARM64 ECS-optimized AMI for cost-effective t4g.small instances
- **User Data Script**: Automatic cluster registration using Terraform template variables
- **Auto Scaling**: 2-4 instance capacity with intelligent scaling policies

## Learning Highlights

### Advanced Terraform Patterns
**Template Variables and Resource Dependencies:**
- Dynamic user data generation using `templatefile()` function
- Circular dependency resolution through proper resource ordering
- ARM64 architecture optimization for cost-effective compute

**Multi-Subnet Resource Placement:**
- Single Auto Scaling Group spanning multiple subnet types
- ECS placement constraints for service-specific subnet targeting
- Resource efficiency through mixed subnet strategies

**IAM Role Separation:**
- Instance-level permissions vs container-level permissions
- Task execution vs task runtime role distinction
- Least-privilege security through role-specific policies

### Infrastructure Design Patterns
**Security Architecture:**
- Network segmentation without over-provisioning
- Security group layering for defense in depth
- Public/private subnet isolation with selective internet access

**Cost Optimization Strategies:**
- Free tier resource maximization
- Lifecycle policies for storage cost management
- Resource sharing through intelligent placement

**Scalability Foundations:**
- Multi-AZ high availability
- Auto Scaling Group integration with ECS capacity providers
- Modular design for independent component scaling

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (version 1.0+)
- Docker for local development and testing

## Deployment Guide

### Step 1: Remote State Setup
```bash
# Create S3 bucket for state
aws s3api create-bucket --bucket skyfox-terraform-state --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning
aws s3api put-bucket-versioning --bucket skyfox-terraform-state --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table --table-name skyfox-terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
```

### Step 2: Deploy Infrastructure
```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply
```

### Step 3: Verify Deployment
```bash
# Verify ECS cluster
aws ecs describe-clusters --clusters skyfox-devprod-cluster

# Check container instances
aws ecs list-container-instances --cluster skyfox-devprod-cluster

# Verify Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names skyfox-devprod-ecs-asg
```
