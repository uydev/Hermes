output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.hermes_backend.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.hermes_backend.id
}

output "backend_url" {
  description = "Backend URL (update DNS to point to this IP)"
  value       = "https://${aws_eip.hermes_backend.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh ubuntu@${aws_eip.hermes_backend.public_ip}"
}
