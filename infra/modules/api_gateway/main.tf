variable "lambda_arn" {
  description = "Lambda function ARN to integrate."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Lambda function invoke ARN for API integration."
  type        = string
}

variable "api_name" {
  description = "Name of the HTTP API."
  type        = string
}

variable "stage_name" {
  description = "Deployment stage name."
  type        = string
}

variable "custom_domain_name" {
  description = "Optional custom domain for this HTTP API (e.g. api.example.com). Leave empty to skip custom domain setup."
  type        = string
  default     = ""
}

variable "api_custom_path" {
  description = "Base path segment for the API mapping on the custom domain (e.g. \"uuid_service\")."
  type        = string
  default     = "uuid_service"
}

locals {
  use_custom_domain = var.custom_domain_name != ""
}

resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_acm_certificate" "api_custom_domain" {
  count = local.use_custom_domain ? 1 : 0

  domain_name       = var.custom_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_domain_name" "custom" {
  count = local.use_custom_domain ? 1 : 0

  domain_name = var.custom_domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api_custom_domain[0].arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "uuid_service" {
  count = local.use_custom_domain ? 1 : 0

  api_id         = aws_apigatewayv2_api.this.id
  domain_name    = aws_apigatewayv2_domain_name.custom[0].domain_name
  stage          = aws_apigatewayv2_stage.this.name
  api_mapping_key = var.api_custom_path
}

output "invoke_url" {
  value = aws_apigatewayv2_stage.this.invoke_url
}

output "custom_domain_name" {
  description = "Custom domain name for the HTTP API, if configured."
  value       = local.use_custom_domain ? aws_apigatewayv2_domain_name.custom[0].domain_name : null
}

output "custom_domain_target" {
  description = "Target domain name for DNS CNAME when using a custom domain."
  value       = local.use_custom_domain ? aws_apigatewayv2_domain_name.custom[0].domain_name_configuration[0].target_domain_name : null
}

output "certificate_dns_validation_records" {
  description = "DNS validation records for the ACM certificate; add these as CNAMEs in Cloudflare."
  value = local.use_custom_domain ? [
    for dvo in aws_acm_certificate.api_custom_domain[0].domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ] : []
}
