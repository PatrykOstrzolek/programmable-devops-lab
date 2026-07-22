# 02 — Terraform + EC2

## Goal

Recreate minimal EC2 infrastructure from Terraform code.

## Outcome

`terraform apply` creates the instance and access rules, and the output displays the server address. `terraform destroy` removes the environment.

## To do

- [ ] Configure providers and variables.
- [ ] Create a security group with restricted SSH and HTTP/HTTPS access.
- [ ] Create a Free Tier eligible instance type.
- [ ] Add an output for the public address.
- [ ] Run `fmt`, `validate`, `plan`, `apply`, and `destroy`.
