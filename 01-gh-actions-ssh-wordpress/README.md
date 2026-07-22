# 01 — GitHub Actions + SSH + WordPress

## Goal

Automatically deploy a custom WordPress theme or plugin to a manually created EC2 instance over SSH.

## Outcome

A push to a selected branch triggers a workflow that synchronizes application files with the server and runs a simple HTTP test.

## To do

- [ ] Manually create an EC2 instance and install WordPress.
- [ ] Add GitHub secrets for the server address, user, and private SSH key.
- [ ] Create a deployment workflow.
- [ ] Deploy an example theme or plugin change.
- [ ] Document how to roll back a change.
