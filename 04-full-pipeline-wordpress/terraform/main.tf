data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
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
    description = "SSH from the administrator and the GitHub Actions runner"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr
  }

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Unrestricted egress is intentional here: the instance needs outbound
  # access to apt mirrors, wordpress.org, and other unpredictable hosts for
  # package updates and the WordPress download, none of which have stable,
  # listable IP ranges.
  # trivy:ignore:AWS-0104
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

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = aws_key_pair.ssh.key_name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted             = true
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name      = "programmable-devops-lab-web"
    Project   = "programmable-devops-lab"
    ManagedBy = "terraform"
  }
}
