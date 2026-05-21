variable "aws_region" {
  description = "AWS region where the CI IAM resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub organization or user that owns the repository (e.g. 'my-org')."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g. 'uuid_service')."
  type        = string
}

variable "github_ref" {
  description = "Git ref this role should trust (e.g. 'refs/heads/main')."
  type        = string
  default     = "refs/heads/main"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository used for the uuid_service images."
  type        = string
  default     = "uuid-service"
}


variable "project_name" {
  description = "Logical project name used for tagging (e.g. 'uuid-service')."
  type        = string
  default     = "uuid-service"
}

variable "environment" {
  description = "Environment label for platform resources (e.g. platform, shared)."
  type        = string
  default     = "platform"
}

variable "tags" {
  description = "Additional tags to apply to platform resources."
  type        = map(string)
  default     = {}
}

