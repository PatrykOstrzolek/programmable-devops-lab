# Guidance for Codex

This directory is for learning, so work in small, verifiable steps. Before making infrastructure changes, show a plan and explain the cost impact.

## Rules

- Do not put secrets in files or Git history.
- For Terraform, run `terraform fmt`, `terraform validate`, and `terraform plan` before `apply`.
- Create a separate, manually triggered workflow for `terraform destroy`.
- Apply least-privilege IAM and keep security group rules as narrow as possible.
- Keep Ansible idempotent; rerunning a playbook should not change the server unnecessarily.
- After every change, document how to run and verify it in the relevant project README.
