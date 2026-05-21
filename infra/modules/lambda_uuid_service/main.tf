variable "function_name" {
  description = "Lambda function name."
  type        = string
}

variable "image_uri" {
  description = "ECR image URI for the Lambda."
  type        = string
}

variable "table_name" {
  description = "UUID DynamoDB table name used by the function."
  type        = string
}

variable "table_arn" {
  description = "UUID DynamoDB table ARN used by the function."
  type        = string
}

resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name = "${var.function_name}-dynamodb"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"],
        Resource = var.table_arn
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  package_type  = "Image"
  image_uri     = var.image_uri
  role          = aws_iam_role.lambda.arn

  environment {
    variables = {
      UUID_TABLE_NAME = var.table_name
    }
  }
}

output "lambda_arn" {
  value = aws_lambda_function.this.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}
