variable "aws_region" {
  description = "AWS Region for the Terraform state bucket."
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Globally unique private S3 bucket name for Terraform state."
  type        = string
  default     = "programmable-devops-lab-tfstate-812047028383"
}
