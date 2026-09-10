variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of existing AWS Key Pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID (Defaults to Ubuntu 26.04 LTS AMI ami-0aba19e56f3eaec05)"
  type        = string
  default     = "ami-0aba19e56f3eaec05"
}
