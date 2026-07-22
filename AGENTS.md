# Guidance for Codex

This directory is for learning, so work in small, verifiable steps. Before making infrastructure changes, show a plan and explain the cost impact.

## Rules

- Do not put secrets in files or Git history.
- For Terraform, run `terraform fmt`, `terraform validate`, and `terraform plan` before `apply`.
- Create a separate, manually triggered workflow for `terraform destroy`.
- Apply least-privilege IAM and keep security group rules as narrow as possible.
- Keep Ansible idempotent; rerunning a playbook should not change the server unnecessarily.
- After every change, document how to run and verify it in the relevant project README.

# AWS Guidance

- Prefer the AWS MCP Server for AWS interactions — it provides sandboxed
  execution, observability, and audit logging. If unavailable, use the
  AWS CLI directly.
- Before starting a task, check whether a relevant AWS skill is available.
  Load the skill with `retrieve_skill` and prefer its guidance over
  general knowledge.
- When uncertain about specific AWS details (API parameters, permissions,
  limits, error codes), verify against documentation rather than guessing.
  State uncertainty explicitly if you cannot confirm.
- When creating infrastructure, prefer infrastructure-as-code (AWS CDK or
  CloudFormation) over direct CLI commands.
- When working with infrastructure, follow AWS Well-Architected Framework
  principles.
- Do not use em dashes in AWS resource names or descriptions. Use
  hyphens instead.

## Secret Safety

- MUST load the `aws-secrets-manager` skill first for any secret,
  credential, API key, token, or password task. MUST NOT call
  `secretsmanager get-secret-value` or `batch-get-secret-value`, and MUST
  NOT hit the Secrets Manager Agent daemon directly. MUST use
  `{{resolve:secretsmanager:secret-id:SecretString:json-key}}` with
  `asm-exec` so the secret resolves at runtime without entering context.
