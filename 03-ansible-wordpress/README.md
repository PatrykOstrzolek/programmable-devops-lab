# 03 — Ansible + WordPress

## Goal

Configure an EC2 server with a repeatable Ansible playbook.

## Outcome

The server receives the required packages, web server configuration, PHP, a database, and WordPress; rerunning the playbook makes no unnecessary changes.

## To do

- [ ] Create an inventory that points to the server from stage 02.
- [ ] Split the configuration into `common`, `web`, `database`, and `wordpress` roles.
- [ ] Store passwords using Ansible Vault or CI secrets.
- [ ] Run the playbook twice and confirm idempotency.
