# How I Built and Deployed a Full-Stack MERN App on AWS EC2 using Docker Compose, Terraform, and GitHub Actions 🚀

Building a full-stack web application from scratch is an exciting journey—from writing clean React components and Express REST APIs to persisting data in MongoDB. However, taking that application from your local machine and deploying it securely to production with HTTPS, custom domains, and automated CI/CD can often feel daunting.

In this tutorial, I will walk you through **how I built an end-to-end full-stack MERN application** and **deployed it to AWS EC2** using **Terraform (Infrastructure as Code)**, **Docker Compose**, **Nginx Reverse Proxy**, **Let's Encrypt (Certbot)** for free HTTPS, and **GitHub Actions** for push-to-deploy CI/CD.

Whether you're a beginner learning full-stack development and DevOps or a developer looking for a reproducible cloud deployment pattern, this guide covers the entire end-to-end workflow! 🛠️

---

## 📱 What is This Project? (Application Overview)

This is a complete full-stack personal diary & management application built from scratch using the MERN stack:

- **React SPA Frontend (client)**: Built with React & Vite. Features interactive diary entry logging, authentication state management, responsive UI, and custom URL shortener views. It is packaged with an optimized Nginx multi-stage Docker build.
- **Node.js & Express API Backend (server)**: Lightweight RESTful API supporting JWT user authentication (Access & Refresh tokens), diary management endpoints, and URL redirection logic.
- **MongoDB Database (mongo)**: Containerized MongoDB instance for persistent storage of users, diary logs, and link analytics.

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

<!-- Image Placeholder: Local Docker Compose application running in browser -->
![Local Docker Application Screenshot](https://raw.githubusercontent.com/ideateGudy/deploy-list/main/docs/images/local-app-running.png)

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
domain_name      = "ideategudy.tech"
```

Initialize and apply the Terraform configuration:
```bash
terraform init
terraform apply -auto-approve
```

<!-- Image Placeholder: Terminal output showing successful terraform apply execution and Elastic IP output -->
![Terraform Apply Terminal Output](https://raw.githubusercontent.com/ideateGudy/deploy-list/main/docs/images/terraform-apply-output.png)

Once complete, Terraform will output your `server_public_ip` (Elastic IP) and `domain_name`. Keep these outputs handy!

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

<!-- Image Placeholder: DNS Settings management page showing A Record and CNAME Record -->
![DNS Records Configuration Screenshot](https://raw.githubusercontent.com/ideateGudy/deploy-list/main/docs/images/dns-configuration.png)

---

### Step 4: Configure GitHub Repository Secrets & Variables

To enable seamless, zero-downtime CI/CD deployment on every code push, navigate to your GitHub Repository:
**Settings > Secrets and variables > Actions**

> 💡 **Tip for Beginners**: You can retrieve all your Terraform output values (like your EC2 Public IP) anytime by running `terraform output` inside the `terraform/` folder!

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

<!-- Image Placeholder: GitHub Repository Settings showing configured Actions secrets and variables -->
![GitHub Actions Secrets & Variables Settings](https://raw.githubusercontent.com/ideateGudy/deploy-list/main/docs/images/github-secrets-settings.png)

---

### Step 5: Automated Deployment via GitHub Actions CI/CD

Our repository includes `.github/workflows/deploy.yml`. 

> 💡 **Note for Beginners**: You do **not** need to manually SSH into your server or build Docker containers on your local computer before pushing! When you push code to GitHub, GitHub Actions automatically connects to your EC2 server, pulls the latest code, issues SSL certificates, and restarts your application containers in the cloud.

When you push changes to the `main` branch:

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

<!-- Image Placeholder: Successful GitHub Actions workflow execution graph -->
![GitHub Actions Pipeline Successful Run](https://raw.githubusercontent.com/ideateGudy/deploy-list/main/docs/images/github-actions-deployment.png)

---

### Step 6: Live Production Verification & Secure HTTPS

Once the GitHub Actions workflow completes successfully, open your browser and navigate to your production domain:
- **Deployed App (HTTPS)**: `https://ideategudy.tech`

<!-- Image Placeholder: Production site live in browser with secure SSL padlock icon -->
![Live Application with SSL Certificate Padlock](https://raw.githubusercontent.com/ideateGudy/deploy-list/main/docs/images/live-app-https.png)

---

### ❓ Troubleshooting & Common Gotchas

If something doesn't work on your first try, don't worry! Here are the most common hiccups beginners face and how to fix them:

1. **SSH Connection Timeout in GitHub Actions**:
   - *Cause*: Security Group blocking SSH or wrong IP.
   - *Fix*: Ensure `allowed_ssh_cidr = "0.0.0.0/0"` in `terraform.tfvars` and check that `EC2_HOST` secret matches your Terraform output IP.
2. **Certbot / SSL Failure**:
   - *Cause*: DNS record has not fully propagated before pushing to GitHub Actions.
   - *Fix*: Run `nslookup yourdomain.com` first to confirm your domain resolves to your EC2 IP before triggering the workflow.
3. **MongoDB Connection Failed**:
   - *Cause*: Containers starting out of order or invalid URI.
   - *Fix*: Make sure `MONGODB_URI` in GitHub Secrets is set to `mongodb://mongo:27017/diarydb` (using the container service name `mongo`).

---

## 🛡️ Production Best Practices Implemented

- **IMDSv2 Enforced**: AWS Instance Metadata Service v2 required for enhanced EC2 protection (`http_tokens = "required"`).
- **EBS Volume Encryption**: Server storage volume (`gp3`) encrypted by default.
- **Log Management**: Docker container logging capped at 10MB per file to prevent disk exhaustion.
- **Enhanced Security Headers**: Nginx configured with `X-Frame-Options`, `X-Content-Type-Options`, and `server_tokens off`.

---

## ⚡ Key Benefits of This Architecture

Choosing this containerized single-server deployment architecture provides several high-value advantages for developers and small-to-medium applications:

1. **💰 Cost Efficiency (AWS Free Tier Friendly)**:
   By running Nginx, Node.js Express, and MongoDB inside a single containerized `t3.micro` EC2 instance with an Elastic IP, you eliminate the overhead of paying for managed load balancers (ALBs) or separate database instances (RDS) during initial rollout or MVP stages.

2. **🔒 Enhanced Security & Internal Networking**:
   - **Internal Docker Bridge**: Backend API (`port 3000`) and MongoDB (`port 27017`) are isolated on internal Docker networks and not exposed directly to the internet.
   - **Nginx Reverse Proxy**: Shields application servers by acting as the sole entry point, handling request routing, rate limiting, and SSL termination.

3. **🔁 Clean Dev-to-Prod Parity with Docker Compose**:
   The exact same `docker-compose.yml` file used for local development runs in production. This eliminates the classic *"it works on my machine"* bugs by ensuring identical runtimes across development and cloud environments.

4. **🚀 Automated Reproducibility (Infrastructure as Code)**:
   With **Terraform**, your entire cloud infrastructure (EC2, VPC, Security Groups, Elastic IP) is defined declaratively as code. Re-creating or destroying your environment requires just a single command (`terraform apply` or `terraform destroy`).

5. **⚡ Frictionless Push-to-Deploy CI/CD**:
   The **GitHub Actions** SSH workflow completely automates the release cycle. Every code push automatically updates code, manages SSL certificates via Certbot, and builds updated containers with zero manual server maintenance required.

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
