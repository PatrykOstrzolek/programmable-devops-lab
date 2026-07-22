data "aws_vpc" "default" {
  default = true
}

resource "aws_key_pair" "ssh" {
  key_name   = "programmable-devops-lab"
  public_key = var.ssh_public_key

  tags = {
    Name      = "programmable-devops-lab"
    Project   = "programmable-devops-lab"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group" "web" {
  name        = "programmable-devops-lab-web"
  description = "Security group for the learning environment"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from the administrator public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "Allow outbound traffic for updates and administration"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "programmable-devops-lab-web"
    Project   = "programmable-devops-lab"
    ManagedBy = "terraform"
  }
}
