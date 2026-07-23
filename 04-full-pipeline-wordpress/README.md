# 04 — Full WordPress pipeline

## Goal

Combine GitHub Actions, Terraform, and Ansible into one controlled deployment process.

## Flow

Manual trigger (`workflow_dispatch`) → Terraform plan → manual approval gate →
Terraform apply → Ansible → HTTP test. A `push` trigger was deliberately left
out for now — see "Deploy workflow" below.

## To do

- [x] Set up GitHub Actions authentication to AWS via OIDC (no long-lived keys).
- [x] Create a `deploy.yml` workflow with manual approval before `apply`.
- [x] Create a `destroy.yml` workflow that can only be triggered manually.
- [x] Pass the EC2 address from Terraform to Ansible dynamic inventory.
- [x] Add a page availability test after deployment.
- [ ] Add brief emergency rollback instructions.

## Bootstrap: GitHub Actions OIDC

`bootstrap/` is a separate Terraform root module (its own state, at
`04-full-pipeline-wordpress/bootstrap/terraform.tfstate` in the shared state
bucket) that creates the one-time account-level trust GitHub Actions needs:

- An IAM OIDC provider for `token.actions.githubusercontent.com`. Its
  `thumbprint_list` is computed at apply time via the `tls_certificate` data
  source rather than hardcoded, to avoid guessing a security-relevant value.
- An IAM role (`programmable-devops-lab-github-actions`) assumable only via
  `sts:AssumeRoleWithWebIdentity`, restricted by the OIDC token's `sub` claim
  to two shapes: jobs running directly on this repo's `main` branch, and jobs
  gated behind the `production` environment (see "Incident" below for why
  both are needed, and why the claim includes numeric IDs).
- An inline policy scoped to what the `04-full-pipeline-wordpress/terraform`
  deploy workflow needs: EC2 management actions, and S3 access limited to the
  `04-full-pipeline-wordpress/terraform/*` prefix of the state bucket.

This had to be applied with admin-level AWS credentials (via `aws login
--profile admin`), not the `programmable-devops-lab-terraform` user used elsewhere in this
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

### Incident: trust policy rejected real GitHub Actions tokens

The very first live run of `deploy.yml` failed at "Configure AWS credentials"
with `Not authorized to perform sts:AssumeRoleWithWebIdentity`, even though
the OIDC provider and role existed and looked correctly configured. CloudTrail
(`aws cloudtrail lookup-events --lookup-attributes
AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity`) showed the
real `sub` claim GitHub sent:

```text
repo:PatrykOstrzolek@18211258/programmable-devops-lab@1309003299:ref:refs/heads/main
```

GitHub includes the owner's and repo's immutable numeric IDs in the `sub`
claim now, not just their names — the trust policy's `StringLike` condition
only matched `repo:OWNER/REPO:ref:...` without the `@ID` suffixes, so every
real token was rejected. Fixed by adding `github_owner_id` and
`github_repository_id` variables (read from the CloudTrail event) and
building the expected `sub` value from them.

While fixing this, a second related issue became clear before it could cause
the same failure in the `deploy` job: GitHub's `sub` claim has a *different*
shape for jobs that reference an `environment:` (`repo:OWNER@ID/REPO@ID:environment:production`)
versus jobs that don't (`repo:OWNER@ID/REPO@ID:ref:refs/heads/main`). The
`plan` job has no environment; `deploy` is gated behind `production`. The
trust policy's `sub` condition now lists both shapes.

Verification: re-applied with `AWS_PROFILE=admin terraform apply` (`1
changed`), then re-ran `deploy.yml`
([run 30001362332](https://github.com/PatrykOstrzolek/programmable-devops-lab/actions/runs/30001362332)).
After approving the `production` environment gate, all three jobs
(`plan`, `deploy`, `smoke-test`) completed successfully — confirming both the
ref-based and environment-based `sub` shapes work, and that the full
pipeline (Terraform apply → Ansible configure → HTTP 200 check) runs
end to end from GitHub Actions for the first time.

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

### Incident: programmable-devops-lab-terraform lacked access to the new state key

The first `apply` created the EC2 instance successfully, but Terraform failed
to save state: `programmable-devops-lab-terraform` (the IAM user used for manual local
Terraform work throughout this lab) only had `s3:PutObject`/`GetObject` on the
single object `02-terraform-ec2/terraform.tfstate` — not the new
`04-full-pipeline-wordpress/terraform/terraform.tfstate` key. Unlike the
GitHub Actions role, `programmable-devops-lab-terraform`'s policy (`TerraformStateBootstrapS3`,
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

Verification: `terraform plan` with the plain `programmable-devops-lab-terraform` credentials
(no `AWS_PROFILE`) reported "No changes. Your infrastructure matches the
configuration," confirming both the fix and that the instance state was
correctly recovered.

Note: this user was renamed from `terraform-secondary` to
`programmable-devops-lab-terraform` afterward, to match this account's naming
convention (`programmable-devops-lab-*`). Renaming an IAM user does not change
its access keys or attached/inline policies, only its ARN, so nothing else in
this lab needed to change.

## State locking

All three S3 backends in this repo (`02-terraform-ec2`,
`04-full-pipeline-wordpress/bootstrap`, `04-full-pipeline-wordpress/terraform`)
now set `use_lockfile = true`, Terraform's native S3 locking (no DynamoDB table
needed). This closes a real gap: without it, `programmable-devops-lab-terraform`
running Terraform locally and a future GitHub Actions deploy could apply
against the same state at the same time and corrupt it.

Native locking writes a companion `<key>.tflock` object next to the state file,
so both `programmable-devops-lab-terraform`'s external policy and the GitHub
Actions role's inline policy needed `s3:GetObject`/`PutObject`/`DeleteObject` on
that object too, not just the `.tfstate` object itself. The GitHub Actions
role's policy already used a prefix wildcard (`.../terraform/*`), so it needed
no change; `programmable-devops-lab-terraform`'s policy lists exact object
ARNs, so both `.tflock` ARNs were added alongside the existing `.tfstate` ones.

## Ansible

`ansible/` is a standalone copy of `03-ansible-wordpress`'s roles and
playbook, same reasoning as the Terraform copy: each stage is its own
self-contained lesson. The secrets are not copied, though — `.vault_pass` and
the vault-encrypted `wordpress_db_password` in `group_vars/web/vault.yml` were
freshly generated for this environment rather than reused from stage 03.

The one real difference is the inventory. Stage 03 used a static
`inventory/hosts.ini` committed to the repo; here the EC2 address isn't known
until after `terraform apply`, and can change on every `destroy`/`apply`
cycle, so `generate-inventory.sh` builds it dynamically:

```bash
#!/usr/bin/env bash
terraform -chdir="../terraform" output -raw public_ip
# → writes inventory/hosts.ini
```

`inventory/hosts.ini` is gitignored — it's a build artifact, regenerated
before every run, not something to track.

Run this from `04-full-pipeline-wordpress/ansible/` (after `terraform apply`
in `../terraform/`):

```bash
./generate-inventory.sh
ansible-playbook site.yml
```

The first run against the new instance needed one extra one-time step: the
host's SSH key wasn't yet trusted, so `ssh ... ubuntu@<ip>` was run once
manually to accept it (`ssh-keyscan` in CI, per the known limitation noted for
stage 03).

Verification: `curl` against the instance returned HTTP 200. Ran the playbook
twice: first run `changed=16`, second run `changed=0`, confirming the copied
roles are still idempotent against the new instance.

## Deploy workflow

`.github/workflows/deploy.yml`, triggered manually from **Actions → Deploy
WordPress pipeline → Run workflow**. Three jobs:

1. **`plan`** — authenticates via OIDC (no stored AWS keys), runs
   `terraform fmt -check`, `init`, `validate`, `plan`. No approval needed;
   nothing changes yet.
2. **`deploy`** — gated behind the `production` GitHub Environment, so it
   pauses for manual approval before running. Runs `terraform apply`, then
   immediately configures the instance with Ansible, **in the same job**. This
   is deliberate, not incidental: the security group only allows SSH from the
   IP that was just added to `admin_cidr`. A separate job for the Ansible step
   could land on a different runner machine with a different IP and get
   locked out of the host `apply` just created — merging the jobs guarantees
   the same IP for both.
3. **`smoke-test`** — `curl`s the instance's public IP and fails the run if it
   doesn't return `200`.

`admin_cidr` is built at runtime as `[vars.ADMIN_CIDR, "<runner IP>/32"]`, so
both the administrator's fixed IP and the current runner's IP are allowed —
matching the "extend the security group" decision made earlier over SSM
Session Manager.

### Required GitHub configuration (one-time, manual)

Repository variables (`Settings → Secrets and variables → Actions →
Variables`, not secret — not sensitive):

- `AWS_DEPLOY_ROLE_ARN` = `arn:aws:iam::812047028383:role/programmable-devops-lab-github-actions`
- `ADMIN_CIDR` = your fixed public IP, e.g. `159.26.110.46/32`
- `SSH_PUBLIC_KEY` = contents of `~/.ssh/id_ed25519.pub` (must match the
  `programmable-devops-lab` key pair Terraform manages)

Repository secrets (same page, `Secrets` tab):

- `SSH_PRIVATE_KEY` = the complete private key matching the public key above,
  including the `BEGIN`/`END` lines
- `ANSIBLE_VAULT_PASSWORD` = the contents of
  `04-full-pipeline-wordpress/ansible/.vault_pass`

Environment protection (`Settings → Environments → New environment` named
`production`, then add yourself as a required reviewer): this is what makes
the `deploy` job actually pause for approval. The workflow file alone cannot
configure this — `environment: production` in the YAML only *references* an
environment; its protection rules are set in the GitHub UI.

### Known limitation: WordPress salts are not stable across CI runs

The `wordpress` role's auth salts are cached locally via Ansible's `password`
lookup (`.wp_salts/`, see the Ansible section above) so repeated *local* runs
reuse the same values. GitHub Actions runners are ephemeral — that cache never
persists between workflow runs — so every `deploy` run currently generates
fresh salts and rewrites `wp-config.php`, which invalidates all logged-in
WordPress sessions on each redeploy. It doesn't break the deployment or lose
data, so this was left as-is rather than fixed now. A real fix would generate
the salts once and store them as GitHub secrets instead of relying on the
lookup cache in CI.

## Destroy workflow

`.github/workflows/destroy.yml`, triggered manually from **Actions → Destroy
WordPress pipeline infrastructure → Run workflow**. Mirrors `deploy.yml`'s
structure:

1. **`plan-destroy`** — ungated, runs `terraform plan -destroy` so you can see
   exactly what would be removed before anything happens.
2. **`destroy`** — gated behind the same `production` environment approval,
   plus one extra safeguard: the workflow requires a `confirm` input, and the
   job's first step fails immediately unless you typed the literal word
   `destroy`. This is on top of the environment approval, not instead of it —
   two independent ways to stop an accidental run.

No Ansible step is needed here, unlike `deploy.yml`: destroying the EC2
instance removes WordPress and its database along with it, there is nothing
left to configure.

Required GitHub configuration is the same as `deploy.yml` — no additional
variables, secrets, or environment setup needed.
