# 01 — GitHub Actions + SSH + WordPress

## Goal

Automatically deploy a custom WordPress theme or plugin to a manually created EC2 instance over SSH.

## Outcome

A push to a selected branch triggers a workflow that synchronizes application files with the server and runs a simple HTTP test.

## To do

- [ ] Manually create an EC2 instance and install WordPress.
- [ ] Add GitHub secrets for the server address, user, and private SSH key.
- [x] Create a manual SSH connectivity workflow.
- [ ] Deploy an example theme or plugin change.
- [ ] Document how to roll back a change.

## SSH connectivity check

The repository contains a manually triggered workflow at `.github/workflows/ssh-check.yml`. It connects to the server and runs `hostname` and `whoami`; it does not deploy files or change the server.

Add these repository secrets in GitHub before running it:

- `SSH_HOST` — the server's public DNS name or IP address.
- `SSH_USER` — the SSH login user, such as `ubuntu`.
- `SSH_PRIVATE_KEY` — the complete private key, including the `BEGIN` and `END` lines.

Run it from **Actions → SSH connectivity check → Run workflow**. A successful run prints the remote hostname and SSH username. A failed run should be investigated before adding deployment steps.

## Verification

On 2026-07-22, workflow run `29937712600` completed successfully. It connected to the EC2 instance and returned the remote hostname and the `ubuntu` SSH user. The workflow did not deploy files or change the server.
