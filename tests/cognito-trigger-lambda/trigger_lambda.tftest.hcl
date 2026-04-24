mock_provider "aws" {}

run "trigger_lambda_local_package" {
  command = plan

  variables {
    function_name = "cognito-trigger-lambda-plan"
    tags          = { Test = "cognito-trigger-lambda" }
  }

  assert {
    condition     = var.function_name == "cognito-trigger-lambda-plan"
    error_message = "Test variables should be set for local zip package run"
  }
}

run "trigger_lambda_with_existing_role" {
  command = plan

  variables {
    function_name            = "cognito-trigger-lambda-existing-role"
    existing_lambda_role_arn = "arn:aws:iam::123456789012:role/cognito-trigger-lambda-test-role"
    tags                     = { Test = "cognito-trigger-lambda-existing-role" }
  }

  assert {
    condition     = var.existing_lambda_role_arn != null && startswith(var.existing_lambda_role_arn, "arn:aws:iam::")
    error_message = "existing_lambda_role_arn should be set for this run"
  }
}
