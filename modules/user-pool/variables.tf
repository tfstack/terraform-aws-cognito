variable "name" {
  description = "Name of the Cognito User Pool"
  type        = string
}

variable "password_policy" {
  description = "Password policy configuration"
  type = object({
    minimum_length                   = number
    require_uppercase                = bool
    require_lowercase                = bool
    require_numbers                  = bool
    require_symbols                  = bool
    temporary_password_validity_days = number
  })
  default = {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }
}

variable "username_attributes" {
  description = "Username attributes for the user pool"
  type        = list(string)
  default     = ["email"]
}

variable "auto_verified_attributes" {
  description = "Auto verified attributes for the user pool"
  type        = list(string)
  default     = ["email"]
}

variable "mfa_configuration" {
  description = "MFA configuration for the user pool (OFF, ON, OPTIONAL)"
  type        = string
  default     = "OFF"
  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be one of: OFF, ON, OPTIONAL."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "domain_prefix" {
  description = "Domain prefix for the Cognito hosted UI. Set to null to skip creating a domain."
  type        = string
  default     = null
}

variable "user_pool_schema" {
  description = "Optional custom attributes (schema blocks) on the user pool. Maps to aws_cognito_user_pool dynamic schema; min_length/max_length are strings per AWS provider."
  type = list(object({
    name                     = string
    attribute_data_type      = string
    mutable                  = optional(bool, true)
    developer_only_attribute = optional(bool, false)
    required                 = optional(bool, false)
    string_attribute_constraints = optional(object({
      min_length = optional(string)
      max_length = optional(string)
    }))
    number_attribute_constraints = optional(object({
      min_value = optional(string)
      max_value = optional(string)
    }))
  }))
  default = []
}

variable "identity_providers" {
  description = "Map of Cognito identity provider name (key) to config. Creates aws_cognito_identity_provider per entry."
  type = map(object({
    provider_type     = string
    provider_details  = map(string)
    attribute_mapping = optional(map(string), {})
    idp_identifiers   = optional(list(string))
  }))
  default = {}
}

variable "identity_provider_ignore_managed_metadata_keys" {
  description = "When true, ignores Cognito-managed SAML provider_details keys that drift after create (ActiveEncryptionCertificate, SLORedirectBindingURI, SSORedirectBindingURI). Use for enterprise SAML metadata URLs."
  type        = bool
  default     = false
}

variable "app_clients" {
  description = "Map of app client name to optional settings. Empty = no clients. Per-client nulls inherit module-level callback_urls, logout_urls, explicit_auth_flows, and allowed_oauth_flows."
  type = map(object({
    generate_secret                      = optional(bool, false)
    supported_identity_providers         = optional(list(string), ["COGNITO"])
    allowed_oauth_scopes                 = optional(list(string), ["email", "openid", "profile"])
    allowed_oauth_flows                  = optional(list(string))
    allowed_oauth_flows_user_pool_client = optional(bool)
    callback_urls                        = optional(list(string))
    logout_urls                          = optional(list(string))
    explicit_auth_flows                  = optional(list(string))
    prevent_user_existence_errors        = optional(string, "ENABLED")
  }))
  default = {}
}

variable "callback_urls" {
  description = "Default callback URLs for app clients when a client does not set callback_urls (hosted UI / OAuth)"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "Default logout URLs for app clients when a client does not set logout_urls"
  type        = list(string)
  default     = []
}

variable "explicit_auth_flows" {
  description = "Default authentication flows for app clients when a client does not set explicit_auth_flows"
  type        = list(string)
  default     = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH"]
}

variable "allowed_oauth_flows" {
  description = "Default OAuth flows when callbacks are enabled and the client does not set allowed_oauth_flows"
  type        = list(string)
  default     = ["code"]
}

variable "user_pool_groups" {
  description = "Map of user pool group names to optional config. Empty map = no groups. e.g. { \"admins\" = { description = \"Admins\", precedence = 1 }, \"users\" = {} }"
  type = map(object({
    description = optional(string, "")
    precedence  = optional(number, 0)
    role_arn    = optional(string)
  }))
  default = {}
}

# ── Pre token generation (optional Lambda trigger) ─────────────────────────
variable "pre_token_generation_lambda_arn" {
  description = "ARN of a Lambda function for Cognito pre token generation. When null, no lambda_config is set on the user pool."
  type        = string
  default     = null
}

variable "pre_token_generation_lambda_version" {
  description = "Cognito pre token generation trigger version (V1_0 legacy payload, V2_0 recommended)"
  type        = string
  default     = "V2_0"
  validation {
    condition     = contains(["V1_0", "V2_0"], var.pre_token_generation_lambda_version)
    error_message = "pre_token_generation_lambda_version must be V1_0 or V2_0."
  }
}

variable "create_pre_token_generation_lambda_permission" {
  description = "When true, grants cognito-idp.amazonaws.com permission to invoke the pre-token Lambda (source_arn = this user pool). Requires pre_token_generation_lambda_function_name."
  type        = bool
  default     = false
}

variable "pre_token_generation_lambda_function_name" {
  description = "Lambda function name (or ARN) for aws_lambda_permission.function_name. Required when create_pre_token_generation_lambda_permission is true."
  type        = string
  default     = null
}

variable "pre_token_generation_lambda_permission_statement_id" {
  description = "Statement ID for aws_lambda_permission when create_pre_token_generation_lambda_permission is true"
  type        = string
  default     = "AllowCognitoUserPoolPreTokenGeneration"
}
