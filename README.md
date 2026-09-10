# Fullstack Diary App - AWS EC2 Deployment Setup

A production-ready fullstack application (React Vite Frontend + Node.js Express Backend + MongoDB Database) configured for deployment on a single AWS EC2 instance using **Docker Compose**, modular **Terraform** Infrastructure-as-Code, and **GitHub Actions** CI/CD.

---

## 🏛️ System Architecture

```
                       ┌────────────────────────────────────────────────────────┐
                       │                   AWS EC2 Instance                     │
                       │                                                        │
                       │    ┌──────────────────────────────────────────────┐    │
                       │    │             Nginx Container (client)         │    │
  User Browser         │    │           Exposes Ports 80 / 443             │    │
┌─────────────┐        │    │                                              │    │
│  HTTP /     ├───────►│    │ - Serves built React SPA frontend            │    │
│  HTTPS      │        │    │ - Reverse proxies /api and /s/ to backend    │    │
└─────────────┘        │    └──────────────────────┬───────────────────────┘    │
                       │                           │                            │
                       │                           ▼                            │
                       │    ┌──────────────────────────────────────────────┐    │
                       │    │         Node.js Express Server (server)      │    │
                       │    │              Internal Port 3000              │    │
                       │    └──────────────────────┬───────────────────────┘    │
                       │                           │                            │
                       │                           ▼                            │
                       │    ┌──────────────────────────────────────────────┐    │
                       │    │               MongoDB (mongo)                │    │
                       │    │            Internal Port 27017               │    │
                       │    └──────────────────────────────────────────────┘    │
                       └────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Directory Overview

```
.
├── client/                     # React Vite Frontend Application
│   ├── Dockerfile              # Multi-stage production Nginx container build
│   └── nginx.conf              # Nginx web server & reverse proxy configuration
├── server/                     # Node.js Express Backend API
│   └── Dockerfile              # Lightweight Node 22 Alpine container build
├── terraform/                  # Terraform IaC Infrastructure Configuration
│   ├── main.tf                 # Root Terraform entry point
│   ├── variables.tf            # Global Terraform variable definitions
│   ├── outputs.tf              # Server Public IP & SSH output definitions
│   └── modules/ec2/            # EC2 module (Instance, Security Group, EIP, UserData)
├── .github/workflows/
│   └── deploy.yml              # GitHub Actions automated SSH deployment pipeline
├── docker-compose.yml          # Local and production multi-container orchestration
└── .env.example                # Sample environment variables reference
```

---

## 🚀 Quick Start & Deployment Guide

### 1. Local Development with Docker Compose

Run the entire application stack locally:
```bash
# Clone the repository
git clone https://github.com/your-username/your-repo.git
cd your-repo

# Build and launch all services
docker compose up -d --build
```
- **Frontend App**: [http://localhost](http://localhost)
- **Backend API**: [http://localhost/api/auth/](http://localhost/api/auth/) *(or direct port: [http://localhost:3000/api/auth/](http://localhost:3000/api/auth/))*
- **Health Check**: [http://localhost/healthz](http://localhost/healthz)

---

### 2. Provision Infrastructure using Terraform

Detailed instructions can be found in [`terraform/README.md`](file:///c:/Users/HP/Desktop/list/terraform/README.md).

```bash
cd terraform

# Create your variables file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS key_name

# Initialize and create AWS resources
terraform init
terraform apply
```

---

### 3. Automated CI/CD Deployment with GitHub Actions

Configure the following **Secrets** under your GitHub Repository (**Settings > Secrets and variables > Actions**):

| Secret Name | Description |
|---|---|
| `EC2_HOST` | Public Elastic IP address of your EC2 instance (Output from Terraform) |
| `EC2_USERNAME` | `ubuntu` |
| `EC2_SSH_KEY` | Contents of your private SSH key (`.pem` file) |
| `MONGODB_URI` | `mongodb://mongo:27017/diarydb` (or external MongoDB Atlas connection URI) |
| `ACCESS_TOKEN_SECRET` | Secure random string for JWT access tokens |
| `REFRESH_TOKEN_SECRET` | Secure random string for JWT refresh tokens |

Configure the following **Variable** under (**Settings > Secrets and variables > Actions > Variables**):

| Variable Name | Description |
|---|---|
| `DOMAIN_NAME` | Custom domain name (e.g. `ideategudy.tech`) |

Every push to the `main` or `master` branch will automatically trigger `.github/workflows/deploy.yml` to deploy updates to your EC2 instance.

---

## 🛡️ Production Best Practices Implemented

- **IMDSv2 Enforced**: AWS Instance Metadata Service v2 is enabled (`http_tokens = "required"`).
- **EBS Encryption**: Root disk volume (`gp3`) encrypted by default.
- **Docker Log Limits**: Automatically caps log size to 10MB per container to prevent disk exhaustion.
- **Security Headers**: Nginx configured with `X-Frame-Options`, `X-Content-Type-Options`, and `server_tokens off`.
