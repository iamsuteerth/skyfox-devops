# ADOT Custom Health Checker

## Overview

This project contains a lightweight Go program and Dockerfile that together provide a robust health check for the AWS Distro for OpenTelemetry (ADOT) Collector container. The health checker is designed to be used as the **ECS container health check command**, ensuring your ADOT sidecar is only marked healthy after its own health check endpoint is live and responding.

- **Language:** Go
- **Purpose:** Programmatically check the ADOT collector health endpoint (`http://localhost:13133`)
- **Use case:** Reliable ECS health check for ADOT in production environments

---

## How It Works

- The Go binary performs an HTTP GET on `http://localhost:13133`
- It returns exit code 0 (success) if it receives HTTP 200 OK, otherwise it prints an error and returns a non-zero status
- This makes it well-suited for ECS `CMD` health checks, more flexible than using `wget` or `curl`

---

## Quick Start: Building and Using the Health Checker

### 1. Clone the Repository

```bash
git clone 
cd adot
# You should have: main.go and Dockerfile in this directory
```

### 2. [Optional] Edit the Health Checker

The code in `main.go` can be easily extended (e.g. add retries, check response body, etc).

### 3. Build the Docker Image (For ARM64)

```bash
# For ARM64, which matches AWS Graviton (t4g) ECS instances:
docker buildx build --platform linux/arm64 -t yourrepo/adot-healthchecker:latest .
```

Or use regular `docker build` for local amd64 development:

```bash
docker build -t yourrepo/adot-healthchecker:latest .
```

### 4. Push to ECR (if needed)

```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin .dkr.ecr.ap-south-1.amazonaws.com

docker tag yourrepo/adot-healthchecker:latest .dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-adot:latest

docker push .dkr.ecr.ap-south-1.amazonaws.com/skyfox-devprod-adot:latest
```

### 5. Update Your ECS Task Definition

Set the container image for your ADOT sidecar to your custom image, and set the health check command:

```json
"healthCheck": {
  "command": ["CMD", "/bin/healthchecker"],
  "interval": 10,
  "timeout": 5,
  "retries": 10,
  "startPeriod": 30
}
```

**Note:** Your ECS task definition for ADOT must mount the healthchecker binary at `/bin/healthchecker`, as per the Dockerfile.

---

## ADOT Configuration Requirements

**Your ADOT collector config must enable the health_check extension:**

```yaml
extensions:
  health_check:
    endpoint: 0.0.0.0:13133
service:
  extensions: [health_check]
```

If this is not present, the health endpoint will not respond and the health check will fail.

---

## Files

- **main.go** – The Go program for the health check.
- **Dockerfile** – Multi-stage Dockerfile to build both the health checker and include it in the ADOT base collector image.

## Customizing the Health Checker

- You can point the check at any URL or port.
- You can add custom logic (such as checking `/healthz` or `/healthcheck`).
- You may extend it to check other dependencies if desired.

---

## Troubleshooting

- If health checks always fail, make sure your ADOT config actually enables the health endpoint (`health_check` extension).
- Test manually: `docker exec -it  /bin/healthchecker`
- Adjust `startPeriod` in the ECS definition if the collector takes longer to start.

---

## Why Use This Custom Checker?

- **More robust** than `wget` or `curl` (better error handling, easily extendable in Go)
- **Easy to maintain** and update whenever requirements change
- **No shell dependencies**—just a single static binary
- **Works for ARM64 and AMD64** with a simple rebuild

> **Note:**  
> This is a **manual solution** implemented because all conventional health check methods for ADOT in ECS (such as shelling out to `wget` or `curl` in the task health check) did **not work reliably**.  
>  
> If you find that standard approaches fail on your AWS ECS setup—even after following the documentation and enabling the `health_check` extension—this Go health checker binary gets the job done every time.

