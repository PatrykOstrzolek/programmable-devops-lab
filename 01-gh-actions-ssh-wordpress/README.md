# 01 — GitHub Actions + SSH + WordPress

## Goal

Automatically deploy a custom WordPress theme or plugin to a manually created EC2 instance over SSH.

## Outcome

A manually triggered workflow connects to the server and runs a controlled SSH check. Deployment automation will be added in a later step.

## To do

- [ ] Manually create an EC2 instance and install WordPress.
- [x] Add GitHub secrets for the server address, user, and private SSH key.
- [x] Create a manual SSH connectivity workflow.
- [ ] Add a read-only server inspection step (`uname`, `df`, `free`, and SSH service status).
- [ ] Add a small temporary file deployment test over SSH.
- [x] Stop the EC2 instance after the SSH exercise.
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

The next inspection run will also collect the operating system version, root filesystem usage, memory summary, and SSH service status. These commands are read-only.

## Next learning steps

Before installing WordPress, extend the workflow in two small increments:

1. Add read-only commands to inspect the operating system, disk space, memory, and SSH service.
2. Create one temporary diagnostic file over SSH and verify its contents.

These exercises demonstrate the difference between inspecting a server and changing it. They also keep the manual EC2 stage small before Terraform and Ansible become responsible for infrastructure and configuration.
