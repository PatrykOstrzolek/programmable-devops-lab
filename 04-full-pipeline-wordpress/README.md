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
- An inline policy scoped to what the `04-full-pipeline-wordpress/terraform`
  deploy workflow needs: EC2 management actions, and S3 access limited to the
  `04-full-pipeline-wordpress/terraform/*` prefix of the state bucket.

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

## Terraform

`terraform/` is a standalone copy of `02-terraform-ec2`'s configuration, not a
shared module — each stage in this repo is its own self-contained lesson, so
stage 02 was left untouched rather than modified in place. Two differences from
the original:

- Its own state key: `04-full-pipeline-wordpress/terraform/terraform.tfstate`.
- `admin_cidr` is `list(string)` instead of `string`, since the security group
  needs to allow both the administrator's IP and, later, the GitHub Actions
  runner's IP during a deploy — not just one.

Before starting stage 04, the stage 02/03 EC2 instance was destroyed (see
`02-terraform-ec2/README.md`) to avoid running two EC2 instances in parallel.

Run this from `04-full-pipeline-wordpress/terraform/`:

```bash
terraform fmt
terraform init
terraform validate
terraform plan -var='admin_cidr=["159.26.110.46/32"]' -var="ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"
terraform apply -var='admin_cidr=["159.26.110.46/32"]' -var="ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"
```

The instance was applied successfully as `i-0e9cc8ed48b69227f`, reachable at
`18.184.85.202` (`ec2-18-184-85-202.eu-central-1.compute.amazonaws.com`).

### Incident: terraform-secondary lacked access to the new state key

The first `apply` created the EC2 instance successfully, but Terraform failed
to save state: `terraform-secondary` (the IAM user used for manual local
Terraform work throughout this lab) only had `s3:PutObject`/`GetObject` on the
single object `02-terraform-ec2/terraform.tfstate` — not the new
`04-full-pipeline-wordpress/terraform/terraform.tfstate` key. Unlike the
GitHub Actions role, `terraform-secondary`'s policy (`TerraformStateBootstrapS3`,
an inline policy on the user) is not managed by Terraform in this repo; it was
set up out of band before this lab's IaC existed.

Recovery:

1. Terraform wrote the unsaved state to a local `errored.tfstate`. Pushed it
   with admin credentials: `AWS_PROFILE=admin terraform state push
   errored.tfstate`.
2. Extended the `TerraformStateBootstrapS3` policy's `ManageTerraformStateObject`
   statement to list both state objects as `Resource`, via
   `aws iam put-user-policy` with admin credentials (not through this repo's
   Terraform, since that policy isn't defined here).

Verification: `terraform plan` with the plain `terraform-secondary` credentials
(no `AWS_PROFILE`) reported "No changes. Your infrastructure matches the
configuration," confirming both the fix and that the instance state was
correctly recovered.
