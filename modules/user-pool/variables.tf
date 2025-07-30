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

variable "app_clients" {
  description = "Map of app client names to optional config. Empty map = no clients created. e.g. { \"web\" = {} }"
  type        = map(any)
  default     = {}
}

variable "callback_urls" {
  description = "Callback URLs for app clients (when using hosted UI)"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "Logout URLs for app clients (when using hosted UI)"
  type        = list(string)
  default     = []
}

variable "explicit_auth_flows" {
  description = "Authentication flows enabled for app clients (e.g. ALLOW_USER_SRP_AUTH, ALLOW_USER_PASSWORD_AUTH, ALLOW_REFRESH_TOKEN_AUTH)"
  type        = list(string)
  default     = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_PASSWORD_AUTH"]
}

variable "allowed_oauth_flows" {
  description = "OAuth flows allowed for app clients when callback_urls are set. Use [\"code\"] for auth code, [\"implicit\"] or [\"code\", \"implicit\"] for token in redirect (e.g. static site)."
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
