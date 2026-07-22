# 02 — Terraform + EC2

## Goal

Recreate minimal EC2 infrastructure from Terraform code.

## Outcome

`terraform apply` creates the instance and access rules, and the output displays the server address. `terraform destroy` removes the environment.

## To do

- [x] Configure providers and variables.
- [ ] Create a security group with restricted SSH and HTTP/HTTPS access.
- [ ] Create a Free Tier eligible instance type.
- [ ] Add an output for the public address.
- [ ] Run `fmt`, `validate`, `plan`, `apply`, and `destroy`.

## Terraform scaffold

The initial scaffold defines the AWS provider and the default `eu-central-1` region. It does not create AWS resources yet.

Run these commands from this directory:

```bash
terraform fmt
terraform init -backend=false
terraform validate
terraform plan
```

Verification: the configuration should format successfully, validate successfully, and produce a plan with no resources to add, change, or destroy.

## State bucket bootstrap

The `bootstrap/` configuration creates the private S3 bucket used by the main Terraform configuration. It intentionally uses the local backend because the remote state bucket must exist before the main backend can use it.

Run these commands from `02-terraform-ec2/bootstrap/`:

```bash
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```

The bootstrap was applied successfully after reviewing the plan:

```text
Apply complete! Resources: 4 added, 1 changed, 0 destroyed.
```

The bucket output was `programmable-devops-lab-tfstate-812047028383` in `eu-central-1`.
The bucket is private, versioned, encrypted with AES256, protected from public access,
and configured with `BucketOwnerEnforced` object ownership.

## Remote backend

The main Terraform configuration uses the bootstrap bucket as an S3 remote backend:

```text
s3://programmable-devops-lab-tfstate-812047028383/02-terraform-ec2/terraform.tfstate
```

Verification completed successfully with `terraform init`, `terraform validate`, and
`terraform plan`. The plan reported no infrastructure changes.

## Security group

The main configuration currently creates one security group in the default VPC. It
allows outbound traffic for updates and administration but has no inbound rules yet.
SSH access will be added later with a CIDR restricted to the administrator's IP.

The security group was applied successfully as `sg-0bd8eeba0ab2bc2e6`. A subsequent
`terraform plan` reported no changes.
