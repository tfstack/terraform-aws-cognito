terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "user_pool" {
  source = "../../modules/user-pool"

  name          = var.user_pool_name
  domain_prefix = var.domain_prefix
  app_clients   = var.app_clients

  user_pool_groups = var.user_pool_groups

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  tags = var.tags

  user_pool_schema                               = var.user_pool_schema
  identity_providers                             = var.identity_providers
  identity_provider_ignore_managed_metadata_keys = var.identity_provider_ignore_managed_metadata_keys

  pre_token_generation_lambda_arn               = var.pre_token_generation_lambda_arn
  pre_token_generation_lambda_version           = var.pre_token_generation_lambda_version
  create_pre_token_generation_lambda_permission = var.create_pre_token_generation_lambda_permission
  pre_token_generation_lambda_function_name     = var.pre_token_generation_lambda_function_name
}
