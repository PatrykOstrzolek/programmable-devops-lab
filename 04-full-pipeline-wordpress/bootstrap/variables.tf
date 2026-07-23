variable "aws_region" {
  description = "AWS Region for this bootstrap configuration."
  type        = string
  default     = "eu-central-1"
}

variable "github_repo" {
  description = "GitHub repository (owner/name) trusted to assume the deploy role via OIDC."
  type        = string
  default     = "PatrykOstrzolek/programmable-devops-lab"
}

variable "github_owner_id" {
  description = "Immutable numeric ID of the GitHub owner, as included in the OIDC sub claim."
  type        = string
  default     = "18211258"
}

variable "github_repository_id" {
  description = "Immutable numeric ID of the GitHub repository, as included in the OIDC sub claim."
  type        = string
  default     = "1309003299"
}

variable "tfstate_bucket_name" {
  description = "Name of the existing Terraform state bucket (created by 02-terraform-ec2/bootstrap)."
  type        = string
  default     = "programmable-devops-lab-tfstate-812047028383"
}