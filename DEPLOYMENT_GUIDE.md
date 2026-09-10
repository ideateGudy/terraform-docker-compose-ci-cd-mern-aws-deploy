# End-to-End Execution and Deployment Guide

This guide documents the complete step-by-step procedure to provision infrastructure on **AWS EC2**, set up automated **CI/CD via GitHub Actions**, and manage the **Docker Compose** containerized stack.

---

## 🛠️ Phase 1: Prerequisites & Initial Setup

Before beginning execution, ensure you have installed:
- [Git](https://git-scm.com/)
- [Docker & Docker Desktop](https://www.docker.com/)
- [AWS CLI](https://aws.amazon.com/cli/) (authenticated via `aws configure`)
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (>= 1.3.0)

### 1.1 Configure AWS Credentials (Dedicated `terraform` IAM User)
Using a dedicated IAM User (e.g. named `terraform`) is an AWS security best practice:

1. **Create IAM User in AWS Console**:
   - Log into your **AWS Management Console**.
   - Navigate to **IAM > Users** and click **Create user**.
   - **User name**: `terraform`
   - **Attach policies directly**: Attach permissions policies required for deployment (e.g., `AdministratorAccess` or `AmazonEC2FullAccess` & `AmazonVPCFullAccess`).
   - Click **Create user**.

2. **Generate Access Keys for `terraform` User**:
   - Click on the newly created **`terraform`** user $\rightarrow$ Go to the **Security credentials** tab.
   - Under **Access keys**, click **Create access key**.
   - Select **Command Line Interface (CLI)**, check the confirmation box, and click **Create access key**.
   - Copy the **Access Key ID** and **Secret Access Key**.

3. **Configure AWS CLI Profile**:
   - Open your terminal and configure default credentials (or a named profile `terraform`):
     ```bash
     # Configure default profile:
     aws configure

     # OR configure as a named profile:
     aws configure --profile terraform
     ```
   - Provide the `terraform` user's keys and region (`us-east-1` or `eu-north-1`).

4. **Verify Authentication**:
   ```bash
   # For default profile:
   aws sts get-caller-identity

   # For named profile:
   aws sts get-caller-identity --profile terraform
   export AWS_PROFILE=terraform
   ```

### 1.2 Create AWS EC2 Key Pair
1. Log into your **AWS Management Console**.
2. Navigate to **EC2 > Key Pairs**.
3. Click **Create Key Pair**.
   - **Name**: `diary-app-key` (or your preferred name)
   - **Key pair type**: `RSA`
   - **Private key file format**: `.pem`
4. Download and store the `.pem` key securely on your local machine (e.g. `~/.ssh/diary-app-key.pem`).
5. Restrict permissions on Linux/macOS:
   ```bash
   chmod 400 ~/.ssh/diary-app-key.pem
   ```

---

## 🏗️ Phase 2: Infrastructure Provisioning (Terraform)

1. Open your terminal and navigate to the project `terraform` directory:
   ```bash
   cd terraform
   ```

2. Copy the sample variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Open `terraform.tfvars` and set your key name and AMI ID:
   ```hcl
   aws_region       = "eu-north-1"
   environment      = "prod"
   instance_type    = "t3.micro"
   key_name         = "ann_notch"            # Matching AWS Key Pair name created in Phase 1
   allowed_ssh_cidr = "0.0.0.0/0"
   ami_id           = "ami-0aba19e56f3eaec05" # Ubuntu Server 26.04 LTS (amd64)
   ```

4. Initialize Terraform modules & providers:
   ```bash
   terraform init
   ```

5. Review the plan to verify resources to be created:
   ```bash
   terraform plan
   ```

6. Apply and create resources:
   ```bash
   terraform apply -auto-approve
   ```

7. **Save the Terraform Outputs**:
   Upon completion, note down the `server_public_ip` printed in your terminal (e.g. `54.210.12.34`).

---

## 🔐 Phase 3: Configure GitHub Repository Secrets

1. Push your project repository to GitHub.
2. In GitHub, navigate to: **Repo > Settings > Secrets and variables > Actions**.
3. Click **New repository secret** for each of the following:

| Secret Name | Example / Value |
|---|---|
| `EC2_HOST` | `54.210.12.34` (The `server_public_ip` from Terraform output) |
| `EC2_USERNAME` | `ubuntu` |
| `EC2_SSH_KEY` | Paste the **FULL** contents of your `.pem` key file (including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`) |
| `MONGODB_URI` | `mongodb://mongo:27017/diarydb` |
| `ACCESS_TOKEN_SECRET` | `a_very_long_secure_random_string_here_123` |
| `REFRESH_TOKEN_SECRET` | `another_very_long_secure_random_string_here_456` |

4. Under the **Variables** tab (**Repo > Settings > Secrets and variables > Actions > Variables**), click **New repository variable**:

| Variable Name | Value |
|---|---|
| `DOMAIN_NAME` | `ideategudy.tech` |

---

## 🌐 Phase 4: Custom Domain & HTTPS Setup (Let's Encrypt)

### 4.1 DNS Configuration
At your domain registrar (e.g. Namecheap, GoDaddy, Cloudflare):
1. **A Record**: Set `@` $\rightarrow$ `server_public_ip` (Your Elastic IP).
2. **CNAME Record**: Set `www` $\rightarrow$ `ideategudy.tech`.

### 4.2 Automated HTTPS SSL Certificate (Certbot)
The CI/CD workflow automatically handles SSL certificate issuance:
- **Nginx HTTP (Port 80)**: Validates ACME challenges (`/.well-known/acme-challenge/`) and redirects all HTTP traffic to HTTPS (`301 https://$host$request_uri`).
- **Nginx HTTPS (Port 443)**: Serves static React assets and proxies `/api/` and `/healthz` securely over SSL using Let's Encrypt certificates (`/etc/letsencrypt/live/${DOMAIN_NAME}/`).

---

## 🚀 Phase 5: Automated CI/CD Execution

1. Commit and push your code to your repository:
   ```bash
   git add .
   git commit -m "Configure AWS EC2 Docker deployment with HTTPS"
   git push origin main
   ```

2. Monitor deployment in GitHub:
   - Navigate to the **Actions** tab in your GitHub repository.
   - Click on the running **Deploy Fullstack App to AWS EC2** workflow.
   - The workflow will automatically connect to your EC2 instance via SSH, pull latest changes, write `.env`, issue/renew Let's Encrypt SSL certificates, and start all containers.

---

## 🧪 Phase 6: Verification & Inspection

### 6.1 Access Web Application
Open your browser and navigate to:
- **Frontend SPA (HTTPS)**: `https://ideategudy.tech`
- **Backend Health Check**: `https://ideategudy.tech/healthz` (returns `{"status":"ok"}`)
- **Backend API**: `https://ideategudy.tech/api/auth/`

### 6.2 Direct SSH Server Inspection (Optional)
Connect directly to the EC2 server:
```bash
ssh -i ~/.ssh/diary-app-key.pem ubuntu@<EC2_PUBLIC_IP>
```

Once connected to the server, you can manage the application stack:
```bash
cd ~/app

# View running container status
sudo docker compose ps

# View real-time container logs
sudo docker compose logs -f

# Restart services manually if needed
sudo docker compose restart
```

---

## ❓ Troubleshooting

### SSH `dial tcp ***:22: i/o timeout` Error in GitHub Actions
If GitHub Actions fails at the SSH step with `i/o timeout`:
1. **Verify `EC2_HOST` Secret**: Check that the `EC2_HOST` secret in **GitHub Settings > Secrets and variables > Actions** matches your current EC2 Elastic IP.
2. **Verify Security Group**: Ensure `allowed_ssh_cidr = "0.0.0.0/0"` in `terraform.tfvars` so GitHub Actions runners can reach port 22.
3. **Verify EC2 Instance State**: Confirm the EC2 instance is in `Running` state in the AWS Console.

---

## 🧹 Teardown & Cleanup

To terminate all AWS resources and prevent incurring costs:
```bash
cd terraform
terraform destroy -auto-approve
```
