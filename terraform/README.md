# Terraform AWS Infrastructure Configuration

This directory contains a simple, modular **Terraform** configuration to provision a single AWS EC2 instance configured to run Docker & Docker Compose.

---

## 🏗️ Architecture & Resources Created

- **AWS EC2 Instance**: Ubuntu 26.04 LTS (`ami-0aba19e56f3eaec05`, `t3.micro` by default) with 20GB encrypted `gp3` root volume.
- **IMDSv2 Protection**: Requires session tokens (`http_tokens = "required"`) to prevent SSRF vulnerabilities.
- **Security Group**: Permits inbound traffic on:
  - Port `22` (SSH)
  - Port `80` (HTTP)
  - Port `443` (HTTPS)
- **Elastic IP (`aws_eip`)**: Static public IP attached to the instance.
- **User Data Script**: Installs Docker CE, Docker Compose plugin, configures Docker log rotation, and sets up 2GB swap space on first boot.

---

## 📋 Prerequisites

1. [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (>= 1.3.0)
2. [AWS CLI](https://aws.amazon.com/cli/) configured with valid AWS credentials:
   ```bash
   aws configure
   ```
3. An existing **AWS Key Pair** created in your AWS Region (e.g., `us-east-1`).

---

## 🚀 Usage Guide

### 1. Configure Variables

Create a `terraform.tfvars` file from the provided example:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with your settings:
```hcl
aws_region       = "us-east-1"
environment      = "prod"
instance_type    = "t3.micro"
key_name         = "your-aws-keypair-name"
allowed_ssh_cidr = "0.0.0.0/0"
```

### 2. Initialize Terraform

Download necessary AWS provider plugins:
```bash
terraform init
```

### 3. Review Implementation Plan

```bash
terraform plan
```

### 4. Provision Resources

```bash
terraform apply
```

Upon completion, Terraform will output:
- `server_public_ip`: Public Elastic IP address of your EC2 instance.
- `ssh_command`: SSH command to connect to the instance.

---

## 🧹 Destroying Resources

To tear down all created infrastructure resources:
```bash
terraform destroy
```

---

## 📄 File Overview

- `main.tf` - Root module invoker.
- `variables.tf` - Input variable definitions.
- `outputs.tf` - Exported values.
- `terraform.tfvars.example` - Example input values.
- `modules/ec2/` - EC2 infrastructure module.
- `modules/ec2/scripts/user_data.sh` - Cloud-init EC2 startup script.
