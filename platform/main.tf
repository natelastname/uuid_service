terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  github_sub = "repo:${var.github_owner}/${var.github_repo}:ref:${var.github_ref}"

  default_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
    },
    var.tags
  )
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}

# GitHub Actions OIDC provider for this AWS account.
# See: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

}

# IAM role assumed by GitHub Actions via OIDC.
resource "aws_iam_role" "github_actions_lambda" {
  name = "github-actions-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = local.github_sub
          }
        }
      }
    ]
  })
}

# Permissions for CI: allow it to push images to ECR. You can
# tighten/extend this later as needed.
resource "aws_iam_role_policy_attachment" "ecr_power_user" {
  role       = aws_iam_role.github_actions_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# ECR repository used by CI and local scripts.
resource "aws_ecr_repository" "uuid_service" {
  name = var.ecr_repository_name

  image_scanning_configuration {
    scan_on_push = true
  }
}
