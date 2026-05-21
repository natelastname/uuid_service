terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "dynamodb_uuids" {
  source     = "./modules/dynamodb_uuids"
  table_name = var.dynamodb_table_name
}

module "uuid_lambda" {
  source        = "./modules/lambda_uuid_service"
  function_name = var.lambda_function_name
  image_uri     = var.lambda_image_uri
  table_name    = module.dynamodb_uuids.table_name
  table_arn     = module.dynamodb_uuids.table_arn
}

module "api_gateway" {
  source            = "./modules/api_gateway"
  lambda_arn        = module.uuid_lambda.lambda_arn
  lambda_invoke_arn = module.uuid_lambda.lambda_invoke_arn
  api_name          = var.api_name
  stage_name        = var.api_stage_name
}
