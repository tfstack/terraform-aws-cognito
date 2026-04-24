locals {
  local_package_ok = var.filename != null && var.source_code_hash != null && var.s3_bucket == null && var.s3_key == null
  s3_package_ok    = var.s3_bucket != null && var.s3_key != null && var.filename == null && var.source_code_hash == null
  use_local        = local.local_package_ok
  use_s3           = local.s3_package_ok
  valid_package    = (local.local_package_ok && !local.s3_package_ok) || (!local.local_package_ok && local.s3_package_ok)

  create_iam_role    = var.lambda_role_arn == null
  execution_role_arn = local.create_iam_role ? aws_iam_role.this[0].arn : var.lambda_role_arn
  iam_role_name      = coalesce(var.iam_role_name, "${var.function_name}-lambda")
}

resource "aws_iam_role" "this" {
  count = local.create_iam_role ? 1 : 0
  name  = local.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = local.create_iam_role ? toset(var.iam_role_managed_policy_arns) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = local.execution_role_arn
  runtime       = var.runtime
  handler       = var.handler
  description   = var.description
  timeout       = var.timeout
  memory_size   = var.memory_size
  publish       = var.publish

  filename         = local.use_local ? var.filename : null
  source_code_hash = local.use_local ? var.source_code_hash : null

  s3_bucket         = local.use_s3 ? var.s3_bucket : null
  s3_key            = local.use_s3 ? var.s3_key : null
  s3_object_version = local.use_s3 && var.s3_object_version != null ? var.s3_object_version : null

  layers = length(var.layers) > 0 ? var.layers : null

  dynamic "environment" {
    for_each = length(var.environment) > 0 ? [1] : []
    content {
      variables = var.environment
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = local.valid_package
      error_message = "Set exactly one deployment mode: (filename + source_code_hash) for a local zip, or (s3_bucket + s3_key) for S3. Do not mix or omit both."
    }
  }

  depends_on = [aws_iam_role_policy_attachment.managed]
}
