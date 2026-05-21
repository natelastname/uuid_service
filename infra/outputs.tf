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
