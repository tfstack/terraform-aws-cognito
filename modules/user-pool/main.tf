# AWS Cognito User Pool
resource "aws_cognito_user_pool" "this" {
  name = var.name

  password_policy {
    minimum_length                   = var.password_policy.minimum_length
    require_lowercase                = var.password_policy.require_lowercase
    require_numbers                  = var.password_policy.require_numbers
    require_symbols                  = var.password_policy.require_symbols
    require_uppercase                = var.password_policy.require_uppercase
    temporary_password_validity_days = var.password_policy.temporary_password_validity_days
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  username_attributes      = var.username_attributes
  auto_verified_attributes = var.auto_verified_attributes
  mfa_configuration        = var.mfa_configuration

  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration != "OFF" ? [1] : []
    content {
      enabled = var.mfa_configuration == "ON"
    }
  }

  tags = var.tags
}

# Optional: User Pool Domain (only when domain_prefix is set)
resource "aws_cognito_user_pool_domain" "this" {
  count        = var.domain_prefix != null ? 1 : 0
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}

# Optional: User Pool Clients (only when app_clients is non-empty)
resource "aws_cognito_user_pool_client" "clients" {
  for_each = var.app_clients

  name         = each.key
  user_pool_id = aws_cognito_user_pool.this.id

  explicit_auth_flows = var.explicit_auth_flows

  allowed_oauth_flows                  = length(var.callback_urls) > 0 ? var.allowed_oauth_flows : []
  allowed_oauth_flows_user_pool_client = length(var.callback_urls) > 0
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  supported_identity_providers         = ["COGNITO"]

  generate_secret               = false
  prevent_user_existence_errors = "ENABLED"
}

# Optional: User Pool Groups (only when user_pool_groups is non-empty)
resource "aws_cognito_user_group" "this" {
  for_each = var.user_pool_groups

  name         = each.key
  user_pool_id = aws_cognito_user_pool.this.id
  description  = each.value.description
  precedence   = each.value.precedence
  role_arn     = each.value.role_arn
}
