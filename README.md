# SkyFox DevOps Infrastructure

## Overview

This repository contains the infrastructure as code (IaC) for the SkyFox project. The infrastructure is provisioned using Terraform and deployed on AWS.

## Architecture

The SkyFox backend consists of three components:
- **Backend Service** (Port 8080): Main application backend
- **Payment Service** (Port 8082): Handles payment processing
- **Movie Service** (Port 4567): Manages movie-related functionality

These services are deployed as Docker containers in an ECS cluster, with traffic routed through an Application Load Balancer using path-based routing:
- `/api` → Backend Service
- `/payment-service` → Payment Service
- `/movie-service` → Movie Service

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
│       ├── ecr/             # 🔄 Docker repositories (planned)
│       ├── ecs/             # 🔄 Container services (planned)
│       └── alb/             # 🔄 Load balancer (planned)
└── gocd/                    # 🔄 CI/CD pipelines (planned)
```

## ✅ Current Status

### Networking Infrastructure
Complete VPC setup with multi-AZ architecture:
- **VPC**: `10.0.0.0/16` across 3 availability zones
- **Public Subnets**: For ALB and backend service (Supabase connectivity)
- **Private Subnets**: For payment and movie services (no internet access)
- **Security Groups**: Configured for each service with least-privilege access

```
ap-south-1a: 10.0.1.0/24 (public) + 10.0.10.0/24 (private)
ap-south-1b: 10.0.2.0/24 (public) + 10.0.20.0/24 (private)  
ap-south-1c: 10.0.3.0/24 (public) + 10.0.30.0/24 (private)
```

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
- Check AWS Console for VPC, subnets, and security groups
- Verify networking components are properly tagged
- Confirm security groups have correct ingress/egress rules
