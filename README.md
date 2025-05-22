# SkyFox DevOps Infrastructure

## Overview

This repository contains the infrastructure as code (IaC) for the SkyFox project. The infrastructure is provisioned using Terraform and deployed on AWS.

## Architecture

The SkyFox backend consists of three component:
- **Backend Service** (Port 8080): Main application backend
- **Payment Service** (Port 8082): Handles payment processing
- **Movie Service** (Port 4567): Manages movie-related functionality

These services are deployed as Docker containers in an ECS cluster, with traffic routed through an Application Load Balancer using path-based routing:
- `/api` → Backend Service
- `/payment-service` → Payment Service
- `/movie-service` → Movie Service

## Getting Started

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (version 1.0+)
- Docker for local development and testing

### Deployment Steps

1. Initialize Terraform:
   ```
   cd terraform
   terraform init
   ```

2. Plan the deployment:
   ```
   terraform plan
   ```

3. Apply the configuration:
   ```
   terraform apply
   ```

# Commands 
## Setting up AWS for remote state
- Create an S3 Bucket to store `terraform` remote state management files.
    ```
    aws s3api create-bucket --bucket skyfox-terraform-state --create-bucket-configuration LocationConstraint=ap-south-1
    ```
- Enable versioning on the `skyfox-terraform-state` bucket
    ```
    aws s3api put-bucket-versioning --bucket skyfox-terraform-state --versioning-configuration Status=Enabled
    ```
- Create a DDB table for state locking
    ```
    aws dynamodb create-table --table-name skyfox-terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
    ```