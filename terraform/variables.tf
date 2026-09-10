variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS Key Pair name for SSH access to EC2"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "Allowed CIDR block for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ami_id" {
  description = "Optional AMI ID override (Defaults to Ubuntu 26.04 LTS ami-0aba19e56f3eaec05)"
  type        = string
  default     = "ami-0aba19e56f3eaec05"
}
