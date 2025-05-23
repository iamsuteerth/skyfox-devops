# SkyFox DevOps Infrastructure

## Overview

This repository contains the infrastructure as code (IaC) for the SkyFox project. The infrastructure is provisioned using Terraform and deployed on AWS.

## Architecture

The SkyFox backend consists of three microservices:
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
├── terraform/               # Terraform configuration files
│   ├── modules/             # Reusable Terraform modules
│   │   ├── networking/      # ✅ VPC, subnets, security groups
│   │   │   ├── main.tf      # Network resource definitions
│   │   │   ├── variables.tf # Input variables
│   │   │   └── outputs.tf   # Exported network values
│   │   ├── ecr/             # 🔄 Docker image repositories (planned)
│   │   ├── ecs/             # 🔄 ECS cluster, services, tasks (planned)
│   │   └── alb/             # 🔄 Application Load Balancer (planned)
│   ├── main.tf              # ✅ Main Terraform configuration
│   ├── variables.tf         # ✅ Global variables
│   └── outputs.tf           # ✅ Root output values
└── README.md                # This file
```

## ✅ Completed Infrastructure Components

### Remote State Management
- **S3 Backend**: Terraform state stored in `skyfox-terraform-state` bucket
- **DynamoDB Locking**: State locks managed via `skyfox-terraform-locks` table
- **Encryption**: State files encrypted at rest

### Networking (VPC)
- **Multi-AZ Setup**: 3 Availability Zones for high availability
- **Public Subnets**: For load balancer and backend service (Supabase connectivity)
- **Private Subnets**: For movie and payment services (no internet access)
- **Cost Optimized**: No NAT Gateway (services use public subnets when needed)

```
VPC: 10.0.0.0/16
├── ap-south-1a
│   ├── Public:  10.0.1.0/24
│   └── Private: 10.0.10.0/24
├── ap-south-1b
│   ├── Public:  10.0.2.0/24
│   └── Private: 10.0.20.0/24
└── ap-south-1c
    ├── Public:  10.0.3.0/24
    └── Private: 10.0.30.0/24
```

## Getting Started

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (version 1.0+)
- Docker for local development and testing

## Setup Instructions

### 1. Set up AWS Remote State Management

Create an S3 bucket for Terraform state:
```bash
aws s3api create-bucket \
  --bucket skyfox-terraform-state \
  --create-bucket-configuration LocationConstraint=ap-south-1
```

Enable versioning on the bucket:
```bash
aws s3api put-bucket-versioning \
  --bucket skyfox-terraform-state \
  --versioning-configuration Status=Enabled
```

Create DynamoDB table for state locking:
```bash
aws dynamodb create-table \
  --table-name skyfox-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. Deploy Networking Infrastructure

Initialize Terraform:
```bash
cd terraform
terraform init
```

Plan the deployment:
```bash
terraform plan
```

Apply the networking configuration:
```bash
terraform apply
```

This creates 16 AWS resources including VPC, subnets, internet gateway, and route tables.

