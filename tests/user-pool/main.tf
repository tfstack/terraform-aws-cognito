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
}
