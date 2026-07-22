variable "aws_region" {
  description = "AWS Region for the learning environment."
  type        = string
  default     = "eu-central-1"
}

variable "admin_cidr" {
  description = "Public IPv4 CIDR allowed to connect to the instance over SSH."
  type        = string
}

variable "ssh_public_key" {
  description = "OpenSSH public key uploaded as the EC2 key pair."
  type        = string
  sensitive   = true
}
