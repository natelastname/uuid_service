output "github_actions_role_arn" {
  description = "IAM role ARN to configure in GitHub Actions (role-to-assume)."
  value       = aws_iam_role.github_actions_lambda.arn
}
