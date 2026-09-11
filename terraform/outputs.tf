output "server_public_ip" {
  description = "Public IP address of the deployed EC2 server"
  value       = module.ec2_app.public_ip
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = module.ec2_app.instance_id
}

output "ssh_command" {
  description = "Sample SSH connection string"
  value       = "ssh -i ../${var.key_name}.pem ubuntu@${module.ec2_app.public_ip}"
}

output "domain_name" {
  description = "Configured application domain name"
  value       = var.domain_name
}

