output "instance_id" {
  description = "ID of the learning EC2 instance."
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IPv4 address of the learning EC2 instance."
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "Public DNS name of the learning EC2 instance."
  value       = aws_instance.web.public_dns
}
