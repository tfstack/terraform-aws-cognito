terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Build a minimal zip for plan-only tests (submodule does not embed archive provider).
data "archive_file" "fixture" {
  type        = "zip"
  output_path = "${path.module}/.terraform/lambda_fixture.zip"
  source {
    content  = "exports.handler = async () => ({ statusCode: 200 });\n"
    filename = "index.js"
  }
}

module "trigger_lambda_local_zip" {
  source = "../../modules/cognito-trigger-lambda"

  function_name    = var.function_name
  runtime          = var.lambda_runtime
  handler          = var.lambda_handler
  filename         = data.archive_file.fixture.output_path
  source_code_hash = data.archive_file.fixture.output_base64sha256

  environment = var.lambda_environment
  tags        = var.tags
}

module "trigger_lambda_existing_role" {
  count  = var.existing_lambda_role_arn != null ? 1 : 0
  source = "../../modules/cognito-trigger-lambda"

  function_name    = "${var.function_name}-existing-role"
  runtime          = var.lambda_runtime
  handler          = var.lambda_handler
  filename         = data.archive_file.fixture.output_path
  source_code_hash = data.archive_file.fixture.output_base64sha256

  lambda_role_arn = var.existing_lambda_role_arn
  tags            = var.tags
}
