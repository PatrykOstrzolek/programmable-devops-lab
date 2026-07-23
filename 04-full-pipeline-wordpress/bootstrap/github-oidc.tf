data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

# GitHub now includes the repository owner's and repo's immutable numeric
# IDs in the OIDC token's `sub` claim (e.g.
# "repo:OWNER@OWNER_ID/REPO@REPO_ID:ref:refs/heads/main"), not just the
# names. A trust policy matching only "repo:OWNER/REPO:ref:..." gets
# "Not authorized to perform sts:AssumeRoleWithWebIdentity" — confirmed via
# CloudTrail on a real failed AssumeRoleWithWebIdentity call. The IDs below
# were read from that CloudTrail event for this specific repo.
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Two allowed shapes: jobs with no "environment:" key present a
    # ref-based sub; jobs that reference an environment (like "deploy",
    # gated behind the "production" environment) present an
    # environment-based sub instead. Both need to be trusted.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.github_owner}@${var.github_owner_id}/${local.github_repo_name}@${var.github_repository_id}:ref:refs/heads/main",
        "repo:${local.github_owner}@${var.github_owner_id}/${local.github_repo_name}@${var.github_repository_id}:environment:production",
      ]
    }
  }
}

locals {
  github_owner     = split("/", var.github_repo)[0]
  github_repo_name = split("/", var.github_repo)[1]
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "programmable-devops-lab-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Name      = "programmable-devops-lab-github-actions"
    Project   = "programmable-devops-lab"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid    = "ManageLearningEc2Resources"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:ModifyInstanceAttribute",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateKeyPair",
      "ec2:ImportKeyPair",
      "ec2:DeleteKeyPair",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${var.tfstate_bucket_name}/04-full-pipeline-wordpress/terraform/*"]
  }

  statement {
    sid       = "TerraformStateListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tfstate_bucket_name}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["04-full-pipeline-wordpress/terraform/*"]
    }
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "programmable-devops-lab-github-actions"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}