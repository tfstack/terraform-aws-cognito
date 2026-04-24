variable "aws_region" {
  description = "AWS region for the test"
  type        = string
  default     = "ap-southeast-2"
}

variable "function_name" {
  description = "Lambda function name for the default module instance"
  type        = string
  default     = "cognito-trigger-lambda-test"
}

variable "lambda_runtime" {
  description = "Lambda runtime for tests"
  type        = string
  default     = "nodejs22.x"
}

variable "lambda_handler" {
  description = "Lambda handler for tests"
  type        = string
  default     = "index.handler"
}

variable "lambda_environment" {
  description = "Optional environment variables for the Lambda under test"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags for resources under test"
  type        = map(string)
  default     = { Test = "true" }
}

variable "existing_lambda_role_arn" {
  description = "When set, exercises the cognito-trigger-lambda path that uses an existing execution role (count = 1)."
  type        = string
  default     = null
}
