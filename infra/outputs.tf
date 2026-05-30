output "api_endpoint" {
  description = "Base URL for the deployed API Gateway HTTP API."
  value       = module.api_gateway.invoke_url
}

output "lambda_function_name" {
  description = "Deployed Lambda function name."
  value       = module.uuid_lambda.function_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table storing UUIDs."
  value       = module.dynamodb_uuids.table_name
}

output "api_custom_domain_name" {
  description = "Custom domain name for the API, if configured."
  value       = module.api_gateway.custom_domain_name
}

output "api_custom_domain_target" {
  description = "Target domain name for DNS CNAME (Cloudflare) when using a custom domain."
  value       = module.api_gateway.custom_domain_target
}

output "api_certificate_dns_validation_records" {
  description = "DNS records for validating the ACM certificate; add them in Cloudflare."
  value       = module.api_gateway.certificate_dns_validation_records
}
