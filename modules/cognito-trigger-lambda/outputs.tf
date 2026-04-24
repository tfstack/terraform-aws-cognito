output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "lambda_role_arn" {
  description = "Execution role ARN (created role or the lambda_role_arn input)"
  value       = local.execution_role_arn
}

output "iam_role_name" {
  description = "Name of the created IAM role, or null when lambda_role_arn was provided"
  value       = local.create_iam_role ? aws_iam_role.this[0].name : null
}
