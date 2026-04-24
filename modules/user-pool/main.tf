locals {
  identity_providers_standard = var.identity_provider_ignore_managed_metadata_keys ? {} : var.identity_providers
  identity_providers_ignored  = var.identity_provider_ignore_managed_metadata_keys ? var.identity_providers : {}

  # True when this client uses effective callback URLs (module default or override) for OAuth-related settings.
  app_client_oauth_enabled = {
    for k, cfg in var.app_clients : k => length(coalesce(cfg.callback_urls, var.callback_urls)) > 0
  }
}

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

  dynamic "schema" {
    for_each = var.user_pool_schema
    content {
      name                     = schema.value.name
      attribute_data_type      = schema.value.attribute_data_type
      mutable                  = schema.value.mutable
      developer_only_attribute = schema.value.developer_only_attribute
      required                 = schema.value.required

      dynamic "string_attribute_constraints" {
        for_each = (
          schema.value.string_attribute_constraints != null && (
            try(schema.value.string_attribute_constraints.min_length, null) != null ||
            try(schema.value.string_attribute_constraints.max_length, null) != null
          )
        ) ? [schema.value.string_attribute_constraints] : []
        content {
          min_length = string_attribute_constraints.value.min_length
          max_length = string_attribute_constraints.value.max_length
        }
      }

      dynamic "number_attribute_constraints" {
        for_each = (
          schema.value.number_attribute_constraints != null && (
            try(schema.value.number_attribute_constraints.min_value, null) != null ||
            try(schema.value.number_attribute_constraints.max_value, null) != null
          )
        ) ? [schema.value.number_attribute_constraints] : []
        content {
          min_value = number_attribute_constraints.value.min_value
          max_value = number_attribute_constraints.value.max_value
        }
      }
    }
  }

  dynamic "lambda_config" {
    for_each = var.pre_token_generation_lambda_arn != null ? [1] : []
    content {
      pre_token_generation_config {
        lambda_arn     = var.pre_token_generation_lambda_arn
        lambda_version = var.pre_token_generation_lambda_version
      }
    }
  }

  tags = var.tags
}

resource "aws_lambda_permission" "pre_token_generation" {
  count = var.create_pre_token_generation_lambda_permission ? 1 : 0

  statement_id  = var.pre_token_generation_lambda_permission_statement_id
  action        = "lambda:InvokeFunction"
  function_name = var.pre_token_generation_lambda_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.this.arn

  lifecycle {
    precondition {
      condition     = var.pre_token_generation_lambda_arn != null
      error_message = "Set pre_token_generation_lambda_arn when create_pre_token_generation_lambda_permission is true."
    }
    precondition {
      condition     = var.pre_token_generation_lambda_function_name != null
      error_message = "Set pre_token_generation_lambda_function_name when create_pre_token_generation_lambda_permission is true."
    }
  }
}

resource "aws_cognito_identity_provider" "standard" {
  for_each = local.identity_providers_standard

  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = each.key
  provider_type = each.value.provider_type

  provider_details  = each.value.provider_details
  attribute_mapping = each.value.attribute_mapping
  idp_identifiers   = each.value.idp_identifiers
}

resource "aws_cognito_identity_provider" "ignore_managed_metadata" {
  for_each = local.identity_providers_ignored

  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = each.key
  provider_type = each.value.provider_type

  provider_details  = each.value.provider_details
  attribute_mapping = each.value.attribute_mapping
  idp_identifiers   = each.value.idp_identifiers

  lifecycle {
    ignore_changes = [
      provider_details["ActiveEncryptionCertificate"],
      provider_details["SLORedirectBindingURI"],
      provider_details["SSORedirectBindingURI"],
    ]
  }
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

  explicit_auth_flows = coalesce(each.value.explicit_auth_flows, var.explicit_auth_flows)

  allowed_oauth_flows = local.app_client_oauth_enabled[each.key] ? coalesce(
    each.value.allowed_oauth_flows,
    var.allowed_oauth_flows,
  ) : []

  allowed_oauth_flows_user_pool_client = coalesce(
    each.value.allowed_oauth_flows_user_pool_client,
    local.app_client_oauth_enabled[each.key],
  )

  allowed_oauth_scopes          = each.value.allowed_oauth_scopes
  callback_urls                 = coalesce(each.value.callback_urls, var.callback_urls)
  logout_urls                   = coalesce(each.value.logout_urls, var.logout_urls)
  supported_identity_providers  = each.value.supported_identity_providers
  generate_secret               = each.value.generate_secret
  prevent_user_existence_errors = each.value.prevent_user_existence_errors

  # Ensure IdPs exist before clients reference them in supported_identity_providers (static depends_on list).
  depends_on = [
    aws_cognito_identity_provider.standard,
    aws_cognito_identity_provider.ignore_managed_metadata,
  ]
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
