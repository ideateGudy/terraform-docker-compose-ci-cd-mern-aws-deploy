provider "aws" {
  region = var.aws_region
}

# Module invocation for EC2 instance & security setup
module "ec2_app" {
  source           = "./modules/ec2"
  environment      = var.environment
  instance_type    = var.instance_type
  key_name         = var.key_name
  allowed_ssh_cidr = var.allowed_ssh_cidr
  ami_id           = var.ami_id
}
