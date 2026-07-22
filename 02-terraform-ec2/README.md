# 02 — Terraform + EC2

## Goal

Recreate minimal EC2 infrastructure from Terraform code.

## Outcome

`terraform apply` creates the instance and access rules, and the output displays the server address. `terraform destroy` removes the environment.

## To do

- [x] Configure providers and variables.
- [x] Create a security group with restricted SSH and HTTP/HTTPS access.
- [x] Create a Free Tier eligible instance type.
- [x] Add an output for the public address.
- [x] Run `fmt`, `validate`, `plan`, `apply`, and `destroy`.

## Terraform scaffold

The initial scaffold defines the AWS provider and the default `eu-central-1` region. It does not create AWS resources yet.

Run these commands from this directory:

```bash
terraform fmt
terraform init -backend=false
terraform validate
terraform plan -var='admin_cidr=YOUR_PUBLIC_IP/32'
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
allows outbound traffic for updates and administration. SSH access is restricted to
the administrator's public IPv4 address through the required `admin_cidr` variable.

For example:

```bash
terraform plan -var='admin_cidr=159.26.110.46/32'
terraform apply -var='admin_cidr=159.26.110.46/32'
```

The security group was applied successfully as `sg-0bd8eeba0ab2bc2e6`. A subsequent
`terraform plan -var='admin_cidr=159.26.110.46/32'` reported no changes.

## EC2 key pair

The configuration also creates the `programmable-devops-lab` EC2 key pair from the
local `~/.ssh/id_ed25519.pub` public key. The private key is never read by Terraform,
committed to Git, or uploaded to AWS.

The key pair was applied successfully, and a subsequent plan reported no changes.

## EC2 instance

The main configuration also creates the learning EC2 instance:

- Ubuntu 24.04 LTS (amd64), looked up via the `aws_ami` data source.
- `t3.micro`, Free Tier eligible.
- 20 GB encrypted `gp3` root volume.
- Public IPv4 address, placed in the default VPC's first subnet (sorted by ID for a
  deterministic choice across applies).
- Attached to the `programmable-devops-lab-web` security group and the
  `programmable-devops-lab` key pair.
- IMDSv2 required (`http_tokens = "required"`).

The security group allows inbound SSH from `admin_cidr` only, and inbound HTTP (80)
and HTTPS (443) from anywhere, so the instance can serve a public website.

Outputs `instance_id`, `public_ip`, and `public_dns` (defined in `outputs.tf`) expose
the instance's address after `apply`.

For example:

```bash
terraform apply -var='admin_cidr=159.26.110.46/32' -var='ssh_public_key=YOUR_PUBLIC_KEY'
```

The instance was applied successfully as `i-0e926d66381a22e45`, reachable at
`51.102.110.245` (`ec2-51-102-110-245.eu-central-1.compute.amazonaws.com`).

Remember to run `terraform destroy` when done to avoid ongoing EC2/public IPv4 costs.

## Destroy

The instance, security group, and key pair were destroyed to avoid running a
duplicate EC2 instance in parallel with the one stage 04 creates:

```bash
terraform destroy -var='admin_cidr=159.26.110.46/32' -var="ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"
```

`Destroy complete! Resources: 3 destroyed.` The state bucket, its bootstrap, and the
stage 04 GitHub Actions OIDC bootstrap were not affected — they live in separate
Terraform state.
