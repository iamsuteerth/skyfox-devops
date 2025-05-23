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

Backend Service → Internal ALB → Payment Service (Private Subnet)
                               → Movie Service   (Private Subnet)
```

**Frontend Communication:**
- Frontend only communicates with Backend Service via External ALB
- All API calls go to `/api` endpoints on Backend

**Backend-to-Services Communication:**
- Backend Service orchestrates calls to Payment and Movie services
- Internal ALB provides load balancing and health checking for internal services
- Path-based routing: `/payment` → Payment Service, `/movie` → Movie Service

### Network Segmentation

**Public Subnets:**
- External ALB (internet-facing)
- Backend (needs Supabase connectivity)

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
│       ├── networking/      # ✅ VPC, subnets, security groups
│       ├── ecr/             # ✅ Docker repositories
│       ├── ecs/             # 🔄 Container services (planned)
│       └── alb/             # 🔄 Load balancer (planned)
└── gocd/                    # 🔄 CI/CD pipelines (planned)
```

## ✅ Current Status

### Networking Infrastructure
Complete VPC setup with multi-AZ architecture and security groups:
- **VPC**: `10.0.0.0/16` across 3 availability zones
- **Public Subnets**: For External ALB and Backend Service
- **Private Subnets**: For Internal ALB and Payment/Movie services
- **Security Groups**: Configured for external ALB, internal ALB, and each service

```
ap-south-1a: 10.0.1.0/24 (public) + 10.0.10.0/24 (private)
ap-south-1b: 10.0.2.0/24 (public) + 10.0.20.0/24 (private)  
ap-south-1c: 10.0.3.0/24 (public) + 10.0.30.0/24 (private)
```

### ECR Infrastructure
Docker repositories for microservices:
- **3 Repositories**: backend, payment-service, movie-service
- **Security**: Vulnerability scanning enabled, AES256 encryption
- **Cost Optimization**: Lifecycle policies (keep 4 images, cleanup after 3 days)
- **CI/CD Ready**: Repository URLs available for GoCD pipelines

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
- **Networking**: Check VPC, subnets, and security groups in AWS Console
- **ECR**: Verify repositories are created with proper lifecycle policies
- **Security**: Confirm proper isolation between public and private subnets
