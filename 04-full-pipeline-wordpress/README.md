# 04 — Full WordPress pipeline

## Goal

Combine GitHub Actions, Terraform, and Ansible into one controlled deployment process.

## Flow

`push` or manual trigger → Terraform plan/apply → Ansible → application deployment → HTTP test.

## To do

- [x] Set up GitHub Actions authentication to AWS via OIDC (no long-lived keys).
- [ ] Create a `deploy.yml` workflow with manual approval before `apply`.
- [ ] Create a `destroy.yml` workflow that can only be triggered manually.
- [ ] Pass the EC2 address from Terraform to Ansible dynamic inventory.
- [ ] Add a page availability test after deployment.
- [ ] Add brief emergency rollback instructions.

## Bootstrap: GitHub Actions OIDC

`bootstrap/` is a separate Terraform root module (its own state, at
`04-full-pipeline-wordpress/bootstrap/terraform.tfstate` in the shared state
bucket) that creates the one-time account-level trust GitHub Actions needs:

- An IAM OIDC provider for `token.actions.githubusercontent.com`. Its
  `thumbprint_list` is computed at apply time via the `tls_certificate` data
  source rather than hardcoded, to avoid guessing a security-relevant value.
- An IAM role (`programmable-devops-lab-github-actions`) assumable only via
  `sts:AssumeRoleWithWebIdentity` from this repo's `main` branch
  (`repo:PatrykOstrzolek/programmable-devops-lab:ref:refs/heads/main`).
- An inline policy scoped to what the `02-terraform-ec2` deploy workflow
  needs: EC2 management actions, and S3 access limited to the
  `02-terraform-ec2/*` prefix of the state bucket.

This had to be applied with admin-level AWS credentials (via `aws login
--profile admin`), not the `terraform-secondary` user used elsewhere in this
lab — creating an OIDC provider and IAM role is intentionally outside that
user's least-privilege scope, so it can't grant itself broader access.

Run this from `04-full-pipeline-wordpress/bootstrap/`:

```bash
terraform fmt
terraform init
terraform validate
AWS_PROFILE=admin terraform plan
AWS_PROFILE=admin terraform apply
```

Verification: applied successfully. `github_actions_role_arn =
"arn:aws:iam::812047028383:role/programmable-devops-lab-github-actions"`.
