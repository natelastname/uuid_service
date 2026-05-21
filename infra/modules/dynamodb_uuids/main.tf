variable "table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

resource "aws_dynamodb_table" "uuids" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"

  attribute {
    name = "uuid"
    type = "S"
  }
}

output "table_name" {
  value = aws_dynamodb_table.uuids.name
}

output "table_arn" {
  value = aws_dynamodb_table.uuids.arn
}
