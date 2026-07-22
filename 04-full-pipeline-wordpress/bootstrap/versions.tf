terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  backend "s3" {
    bucket = "programmable-devops-lab-tfstate-812047028383"
    key    = "04-full-pipeline-wordpress/bootstrap/terraform.tfstate"
    region = "eu-central-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}