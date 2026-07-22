terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  backend "s3" {
    bucket = "programmable-devops-lab-tfstate-812047028383"
    key    = "02-terraform-ec2/terraform.tfstate"
    region = "eu-central-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
