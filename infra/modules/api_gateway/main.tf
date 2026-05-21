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

resource "aws_apigatewayv2_route" "get_uuid" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /uuid"
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

output "invoke_url" {
  value = aws_apigatewayv2_stage.this.invoke_url
}
