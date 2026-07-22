# 04 — Full WordPress pipeline

## Goal

Combine GitHub Actions, Terraform, and Ansible into one controlled deployment process.

## Flow

`push` or manual trigger → Terraform plan/apply → Ansible → application deployment → HTTP test.

## To do

- [ ] Create a `deploy.yml` workflow with manual approval before `apply`.
- [ ] Create a `destroy.yml` workflow that can only be triggered manually.
- [ ] Pass the EC2 address from Terraform to Ansible dynamic inventory.
- [ ] Add a page availability test after deployment.
- [ ] Add brief emergency rollback instructions.
