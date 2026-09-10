output "public_ip" {
  description = "Public IP address of the allocated Elastic IP"
  value       = aws_eip.app_eip.public_ip
}

output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.app_server.id
}

output "security_group_id" {
  description = "ID of the created Security Group"
  value       = aws_security_group.web_sg.id
}
