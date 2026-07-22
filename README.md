# Programmable DevOps Lab

A practical learning path for GitHub Actions, Terraform, and Ansible through small WordPress projects.

## Separation of responsibilities

| Tool | Responsibility |
| --- | --- |
| GitHub Actions | Automates checks, deployments, and infrastructure runs. |
| Terraform | Creates and removes AWS resources: networking, access rules, and EC2. |
| Ansible | Configures the operating system and application on the provisioned server. |

## Project sequence

1. [01-gh-actions-ssh-wordpress](./01-gh-actions-ssh-wordpress/) — deploy WordPress changes over SSH.
2. [02-terraform-ec2](./02-terraform-ec2/) — EC2 infrastructure defined as code.
3. [03-ansible-wordpress](./03-ansible-wordpress/) — repeatable server and WordPress configuration.
4. [04-full-pipeline-wordpress](./04-full-pipeline-wordpress/) — full pipeline: infrastructure, configuration, deployment, and test.

## Security and costs

- Before the first deployment, configure a budget alert in AWS.
- Do not commit SSH keys, AWS tokens, or `.tfvars` files containing secrets to the repository.
- Allow SSH only from required IP addresses; do not use `0.0.0.0/0` except for a short, deliberate test.
- After an exercise, run `terraform destroy` and check for remaining volumes, Elastic IPs, or other resources.

## Repository setup

Create the local Git repository and publish it to GitHub before adding workflows:

```bash
git init
git add .
git commit -m "docs: add DevOps learning roadmap"
```

Create an empty GitHub repository named `programmable-devops-lab`, without a README, license, or `.gitignore`. Then connect and push the local repository:

```bash
git branch -M main
git remote add origin git@github.com:<YOUR_GITHUB_USERNAME>/programmable-devops-lab.git
git push -u origin main
```

Verify the setup by opening the GitHub repository and confirming that the `main` branch contains this README and all four project directories.

## Definition of done for each stage

Each project should include its own `README.md`, run instructions, a list of secrets and variables used, and a short “What I learned” section.
