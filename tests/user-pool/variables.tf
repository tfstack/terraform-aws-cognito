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
  description = "Map of app client names"
  type        = map(any)
  default     = {}
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
