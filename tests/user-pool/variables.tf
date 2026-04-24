variable "aws_region" {
  description = "AWS region for the test"
  type        = string
  default     = "ap-southeast-2"
}

variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
}

variable "domain_prefix" {
  description = "Domain prefix for the Cognito hosted UI (null to skip)"
  type        = string
  default     = null
}

variable "app_clients" {
  description = "Map of app client names to optional config (matches modules/user-pool app_clients type)"
  type        = any
  default     = {}
}

variable "user_pool_schema" {
  description = "Optional custom schema entries for the user pool under test"
  type        = any
  default     = []
}

variable "identity_providers" {
  description = "Optional identity providers map for the user pool under test"
  type        = any
  default     = {}
}

variable "identity_provider_ignore_managed_metadata_keys" {
  description = "When true, use IdP resource with lifecycle ignore on SAML metadata keys"
  type        = bool
  default     = false
}

variable "user_pool_groups" {
  description = "Map of user pool group names to optional config"
  type = map(object({
    description = optional(string, "")
    precedence  = optional(number, 0)
    role_arn    = optional(string)
  }))
  default = {}
}

variable "callback_urls" {
  description = "Callback URLs for app clients"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "Logout URLs for app clients"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

variable "pre_token_generation_lambda_arn" {
  description = "Optional pre-token Lambda ARN for the user pool under test"
  type        = string
  default     = null
}

variable "pre_token_generation_lambda_version" {
  description = "Pre-token trigger version (V1_0 or V2_0)"
  type        = string
  default     = "V2_0"
}

variable "create_pre_token_generation_lambda_permission" {
  description = "Whether to create aws_lambda_permission for the pre-token function"
  type        = bool
  default     = false
}

variable "pre_token_generation_lambda_function_name" {
  description = "Lambda function name for aws_lambda_permission (when permission is enabled)"
  type        = string
  default     = null
}
