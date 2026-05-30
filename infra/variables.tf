variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function."
  type        = string
  default     = "uuid-service"
}

variable "lambda_image_uri" {
  description = "ECR image URI for the Lambda container image."
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table storing UUIDs."
  type        = string
  default     = "uuid_service_uuids"
}

variable "api_name" {
  description = "Name of the API Gateway HTTP API."
  type        = string
  default     = "uuid-service-api"
}

variable "api_stage_name" {
  description = "Deployment stage name for the API Gateway HTTP API."
  type        = string
  default     = "prod"
}

variable "api_custom_domain_name" {
  description = "Optional custom domain name for the API Gateway HTTP API (e.g. api.example.com). Leave empty to skip custom domain configuration."
  type        = string
  default     = ""
}

variable "api_custom_path" {
  description = "Base path segment for the API when using a custom domain (e.g. \"uuid_service\")."
  type        = string
  default     = "uuid_service"
}

variable "project_name" {
  description = "Logical project name used for tagging (e.g. 'uuid-service')."
  type        = string
  default     = "uuid-service"
}


variable "environment" {
  description = "Environment name for this stack (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Additional tags to apply to all infra resources."
  type        = map(string)
  default     = {}
}

