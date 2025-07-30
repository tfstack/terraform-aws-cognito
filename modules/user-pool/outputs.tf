output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_endpoint" {
  description = "The endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.endpoint
}

output "domain_name" {
  description = "The domain name of the Cognito hosted UI (only set when domain_prefix was provided)"
  value       = var.domain_prefix != null ? one(aws_cognito_user_pool_domain.this[*].domain) : null
}

output "client_ids" {
  description = "Map of app client name to client ID (only set when app_clients was non-empty)"
  value       = { for k, c in aws_cognito_user_pool_client.clients : k => c.id }
}

output "user_pool_client_ids" {
  description = "List of Cognito User Pool Client IDs (for backward compatibility)"
  value       = [for c in aws_cognito_user_pool_client.clients : c.id]
  sensitive   = true
}

output "user_pool_group_names" {
  description = "Names of the user pool groups (for use with aws_cognito_user_in_group)"
  value       = [for g in aws_cognito_user_group.this : g.name]
}
