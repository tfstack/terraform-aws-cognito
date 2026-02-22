terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

data "aws_region" "current" {}

variable "demo_user_username" {
  description = "Username (email) for the demo Cognito user. Set in tfvars."
  type        = string
  default     = "demo@example.com"
}

# Unique bucket name for demo
resource "random_string" "bucket_suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# Temporary password for demo user (must meet pool policy: length, upper, lower, number, symbol)
resource "random_password" "demo_user" {
  length      = 16
  special     = true
  upper       = true
  lower       = true
  numeric     = true
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
  min_special = 1
}

# S3 bucket for static demo site (private; served via CloudFront)
resource "aws_s3_bucket" "demo" {
  bucket = "cognito-basic-demo-${random_string.bucket_suffix.result}"
}

resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront origin access control
resource "aws_cloudfront_origin_access_control" "demo" {
  name                              = "cognito-basic-demo-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution for HTTPS access to S3 (Cognito requires HTTPS callback)
resource "aws_cloudfront_distribution" "demo" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.demo.bucket_regional_domain_name
    origin_id                = "s3-demo"
    origin_access_control_id = aws_cloudfront_origin_access_control.demo.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-demo"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Allow CloudFront to read from the S3 bucket
resource "aws_s3_bucket_policy" "demo" {
  bucket = aws_s3_bucket.demo.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFront"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.demo.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.demo.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.demo]
}

locals {
  site_url     = "https://${aws_cloudfront_distribution.demo.domain_name}"
  callback_url = "https://${aws_cloudfront_distribution.demo.domain_name}/callback.html"
  logout_url   = "https://${aws_cloudfront_distribution.demo.domain_name}/"
}

module "user_pool" {
  source = "../../modules/user-pool"

  name          = "basic-example-users"
  domain_prefix = "basic-example"
  app_clients   = { "web" = {} }

  user_pool_groups = {
    "admin" = {
      description = "Administrators with full access"
      precedence  = 1
    }
    "readonly" = {
      description = "Read-only users"
      precedence  = 2
    }
  }

  callback_urls       = [local.callback_url]
  logout_urls         = [local.logout_url]
  allowed_oauth_flows = ["implicit"]

  tags = {
    Environment = "example"
    Project     = "cognito-basic"
  }
}

resource "aws_cognito_user" "demo" {
  user_pool_id = module.user_pool.user_pool_id
  username     = var.demo_user_username

  attributes = {
    email          = var.demo_user_username
    email_verified = "true"
  }

  temporary_password = random_password.demo_user.result
  message_action     = "SUPPRESS"

  depends_on = [module.user_pool]
}

resource "aws_cognito_user_in_group" "demo" {
  user_pool_id = module.user_pool.user_pool_id
  group_name   = "admin"
  username     = aws_cognito_user.demo.username
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.demo.id
  key          = "index.html"
  content_type = "text/html"
  content = templatefile("${path.module}/index.html.tpl", {
    domain       = module.user_pool.domain_name
    region       = data.aws_region.current.id
    client_id    = module.user_pool.client_ids["web"]
    redirect_uri = urlencode(local.callback_url)
  })
}

resource "aws_s3_object" "callback" {
  bucket       = aws_s3_bucket.demo.id
  key          = "callback.html"
  content_type = "text/html"
  content      = file("${path.module}/callback.html")
}

resource "aws_s3_object" "favicon" {
  bucket       = aws_s3_bucket.demo.id
  key          = "favicon.png"
  content_type = "image/png"
  source       = "${path.module}/favicon.png"
}

output "demo_site_url" {
  description = "Open this URL in the browser to start the demo"
  value       = local.site_url
}

output "demo_user" {
  description = "Username (email) for manual login"
  value       = var.demo_user_username
}

output "demo_password" {
  description = "Temporary password for demo user (use for manual login)"
  value       = random_password.demo_user.result
  sensitive   = true
}

output "hosted_ui_url" {
  description = "Cognito Hosted UI (for reference)"
  value       = "https://${module.user_pool.domain_name}.auth.${data.aws_region.current.id}.amazoncognito.com"
}
