# From Zero to Production: How to Deploy a Containerized Full-Stack App on AWS EC2 with Terraform, Nginx, and GitHub Actions 🚀

Deploying a modern full-stack web application to production can feel like juggling flaming torches—especially if you're trying to figure out how Docker containers, Terraform, Nginx, SSL certificates, and GitHub Actions all fit together.

Whether you're a beginner taking your first steps into DevOps or a developer looking for a clean, reproducible production deployment pattern, this guide is for you!

In this tutorial, we will take a full-stack application (**React Frontend + Node.js/Express Backend + MongoDB Database**) and deploy it to **AWS EC2** using **Terraform (Infrastructure as Code)**, **Docker Compose**, **Nginx Reverse Proxy**, **Let's Encrypt (Certbot)** for free HTTPS, and **GitHub Actions** for automated continuous deployment (CI/CD).

Let's break it down step-by-step! 🛠️

---

## 📋 Prerequisites & Tools Required

Before we begin, ensure you have the following installed and set up on your machine:

1. **[Git](https://git-scm.com/)**: Version control system to manage project code.
2. **[Docker & Docker Desktop](https://www.docker.com/)**: To build and test containerized services locally.
3. **[AWS CLI](https://aws.amazon.com/cli/)**: Configured with IAM credentials (`aws configure`).
4. **[Terraform CLI](https://developer.hashicorp.com/terraform/downloads)** (v1.3.0 or higher): To provision AWS infrastructure declaratively.
5. **AWS Account**: An active AWS account with permissions to launch EC2, VPC, Security Groups, and Elastic IPs.
6. **Custom Domain Name**: (Optional but recommended) A domain name pointing to AWS (e.g. from Namecheap, Cloudflare, GoDaddy).

---

## 🏛️ High-Level System Architecture

Here is how all the moving parts work together once deployed on AWS:

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

### Key Architectural Highlights:
- **Nginx (Frontend Container)**: Listens on standard public ports `80` (HTTP) and `443` (HTTPS). It serves the production React build and acts as a **reverse proxy**, forwarding `/api/` traffic to the backend server.
- **Node.js Express (Backend Container)**: Communicates internally over Docker's bridge network (`port 3000`). It is **not** directly exposed to the public internet, adding a layer of security.
- **MongoDB (Database Container)**: Persists application state internally (`port 27017`) using Docker named volumes.

---

## 📁 Repository Structure Overview

Here is the clean layout of our project repository:

```text
.
├── client/                     # React Frontend Application (Vite + Nginx Dockerfile)
│   ├── Dockerfile              # Multi-stage build (Node build -> Nginx runtime)
│   └── nginx.conf              # Nginx web server & reverse proxy configuration
├── server/                     # Node.js Express Backend API
│   └── Dockerfile              # Lightweight Node 22 Alpine container build
├── terraform/                  # Terraform IaC Infrastructure Code
│   ├── main.tf                 # Root Terraform entry point
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Server Public IP & SSH output definitions
│   └── modules/ec2/            # EC2 module (Instance, Security Group, EIP, UserData)
├── .github/workflows/
│   └── deploy.yml              # GitHub Actions automated SSH deployment pipeline
├── docker-compose.yml          # Multi-container orchestration config
└── .env.example                # Sample environment variables reference
```

---

## 🚀 Step-by-Step Deployment Walkthrough

### Step 1: Local Development & Container Verification

First, verify that your multi-container application runs smoothly on your local machine using Docker Compose:

```bash
# 1. Clone the repository
git clone https://github.com/ideateGudy/deploy-list.git
cd deploy-list

# 2. Copy sample environment file
cp .env.example .env

# 3. Build and launch containers locally
docker compose up -d --build
```

You can test your application at:
- **Frontend SPA**: `http://localhost`
- **Backend API**: `http://localhost/api/auth/`
- **Health Check**: `http://localhost/healthz`

---

### Step 2: Provision Infrastructure using Terraform (IaC)

Instead of manually clicking through the AWS Console, we use **Terraform** to provision an EC2 instance, an Elastic IP (static IP), Security Groups (firewall rules), and install Docker via automated `user_data` scripts.

#### 1. Configure AWS CLI & Security Key Pair
Make sure your AWS CLI is authenticated and generate an AWS EC2 Key Pair (e.g. `ann_notch` or `diary-app-key`).

#### 2. Provision with Terraform
```bash
# Navigate to terraform directory
cd terraform

# Create your tfvars configuration file
cp terraform.tfvars.example terraform.tfvars
```

Edit your `terraform.tfvars`:
```hcl
aws_region       = "eu-north-1"
environment      = "prod"
instance_type    = "t3.micro"
key_name         = "ann_notch"            # Your AWS SSH Key Pair name
allowed_ssh_cidr = "0.0.0.0/0"
ami_id           = "ami-0aba19e56f3eaec05" # Ubuntu 26.04 LTS (amd64)
```

Initialize and apply the Terraform configuration:
```bash
terraform init
terraform apply -auto-approve
```

Once complete, Terraform will output your `server_public_ip` (Elastic IP). Keep this IP handy!

---

### Step 3: Configure Custom Domain & DNS Records (Optional but Recommended)

To make your application accessible at a real domain (e.g., `ideategudy.tech`) and issue SSL certificates:

1. Go to your Domain Registrar DNS settings.
2. Create an **A Record**: Name `@` $\rightarrow$ Value `<YOUR_SERVER_PUBLIC_IP>`.
3. Create a **CNAME Record**: Name `www` $\rightarrow$ Value `ideategudy.tech`.
4. Verify DNS propagation:
   ```bash
   nslookup ideategudy.tech 8.8.8.8
   ```

---

### Step 4: Configure GitHub Repository Secrets & Variables

To enable seamless, zero-downtime CI/CD deployment on every code push, navigate to your GitHub Repository:
**Settings > Secrets and variables > Actions**

Add the following **Repository Secrets**:

| Secret Name | Value / Description |
|---|---|
| `EC2_HOST` | Public Elastic IP address from Terraform output |
| `EC2_USERNAME` | `ubuntu` |
| `EC2_SSH_KEY` | Entire private SSH key contents (`.pem` file) |
| `MONGODB_URI` | `mongodb://mongo:27017/diarydb` |
| `ACCESS_TOKEN_SECRET` | Secure random secret string for JWT access |
| `REFRESH_TOKEN_SECRET` | Secure random secret string for JWT refresh |

Add the following **Repository Variable**:

| Variable Name | Value / Description |
|---|---|
| `DOMAIN_NAME` | `ideategudy.tech` (or your domain name) |

---

### Step 5: Automated Deployment via GitHub Actions CI/CD

Our repository includes `.github/workflows/deploy.yml`. When you push changes to the `main` branch:

1. GitHub Actions connects securely to your EC2 server via SSH.
2. It pulls the latest code.
3. It updates environment variables (`.env`).
4. It executes Certbot to issue/renew free Let's Encrypt SSL certificates automatically.
5. It runs `docker compose up -d --build` to re-deploy updated containers with zero downtime.

To trigger your deployment:
```bash
git add .
git commit -m "Deploy fullstack application to production"
git push origin main
```

Head over to the **Actions** tab in GitHub to watch your deployment complete in real-time! ⚡

---

## 🛡️ Production Best Practices Implemented

- **IMDSv2 Enforced**: AWS Instance Metadata Service v2 required for enhanced EC2 protection (`http_tokens = "required"`).
- **EBS Volume Encryption**: Server storage volume (`gp3`) encrypted by default.
- **Log Management**: Docker container logging capped at 10MB per file to prevent disk exhaustion.
- **Enhanced Security Headers**: Nginx configured with `X-Frame-Options`, `X-Content-Type-Options`, and `server_tokens off`.

---

## 🎯 Conclusion

Congratulations! 🥳 You've built and deployed a production-ready, containerized full-stack application on AWS!

Here is a quick recap of what we accomplished:
1. Orchestrated local multi-container environments using **Docker Compose**.
2. Automated cloud infrastructure provisioning using **Terraform**.
3. Established secure reverse-proxying and routing with **Nginx**.
4. Automated SSL HTTPS certificate generation via **Let's Encrypt & Certbot**.
5. Built a push-to-deploy CI/CD pipeline using **GitHub Actions**.

Infrastructure-as-Code and containerization give you complete confidence that your deployment is reproducible, maintainable, and scalable.

---

## 🤝 Connect & Follow Me

If you found this guide helpful, hit the ❤️ button, bookmark it for later, and feel free to connect with me!

- 🐙 **GitHub**: [github.com/ideateGudy](https://github.com/ideateGudy)
- 💼 **LinkedIn**: [linkedin.com/in/ideategudy](https://www.linkedin.com/in/ideategudy/)

Got questions or run into issues? Drop a comment below—I'd love to help out! Happy coding! 🚀
