variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g. nodejs24.x, python3.12)"
  type        = string
}

variable "handler" {
  description = "Lambda handler (e.g. index.handler)"
  type        = string
}

# ── Deployment package: local zip OR S3 (mutually exclusive) ─────────────────
variable "filename" {
  description = "Path to deployment package (zip). Use with source_code_hash. Mutually exclusive with s3_bucket/s3_key."
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package (required when filename is set)"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment package. Mutually exclusive with filename/source_code_hash."
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 object key for the deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Optional S3 object version ID"
  type        = string
  default     = null
}

# ── IAM: pass an existing role, or create one with managed policy attachments ─
variable "lambda_role_arn" {
  description = "Existing IAM role ARN for the Lambda execution role. When null, a role is created using iam_role_managed_policy_arns."
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name for the created IAM role (only when lambda_role_arn is null). When null, the role name is derived from function_name."
  type        = string
  default     = null
}

variable "iam_role_managed_policy_arns" {
  description = "Managed policy ARNs to attach when creating the execution role (lambda_role_arn is null). Must be non-empty when a role is created."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  validation {
    condition     = var.lambda_role_arn != null || length(var.iam_role_managed_policy_arns) > 0
    error_message = "When lambda_role_arn is null, iam_role_managed_policy_arns must contain at least one policy ARN."
  }
}

variable "tags" {
  description = "Tags for Lambda and created IAM role"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 3
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 128
}

variable "layers" {
  description = "List of Lambda layer version ARNs"
  type        = list(string)
  default     = []
}

variable "vpc_config" {
  description = "VPC configuration for the function. Set to null to run outside a VPC."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "publish" {
  description = "Whether to publish a version alias"
  type        = bool
  default     = false
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = null
}
