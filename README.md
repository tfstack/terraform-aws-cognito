# terraform-aws-cognito

Terraform modules for AWS Cognito. The repository uses a multi-module layout so you can use only what you need.

## Layout

- **modules/user-pool** – Cognito User Pool with optional **custom attributes** (`user_pool_schema`), optional **SAML/OIDC identity providers**, optional domain (hosted UI), configurable **app clients** (per-client OAuth URLs, `generate_secret`, `supported_identity_providers`, scopes), optional **pre token generation** Lambda wiring (`lambda_config` + optional `aws_lambda_permission`), and optional groups. Use this for authentication (sign-up, sign-in, JWT) from simple hosted UI through federated enterprise setups.
- **modules/cognito-trigger-lambda** – Generic **Lambda execution package** (local zip or S3) and optional IAM execution role for functions you attach as Cognito User Pool triggers. Does **not** create `aws_lambda_permission` (avoid module cycles with the user pool); use **modules/user-pool** flags or define the permission at the root module.
- **modules/identity-pool** – Placeholder for future use (Cognito Identity Pool / Federated Identity for temporary AWS credentials).

## Usage (user-pool)

Minimal example: user pool with a domain and one app client.

```hcl
module "user_pool" {
  source = "./modules/user-pool"

  name          = "my-app-users"
  domain_prefix = "my-app-auth"      # optional: set to null to skip hosted UI domain
  app_clients   = { "web" = {} }     # optional: empty map = no clients

  user_pool_groups = {               # optional: groups (cognito:groups in ID token)
    "admin"    = { description = "Admins", precedence = 1 }
    "readonly" = { description = "Read-only", precedence = 2 }
  }

  callback_urls = ["https://myapp.example.com/callback"]
  logout_urls   = ["https://myapp.example.com/logout"]

  tags = { Environment = "prod" }
}

output "user_pool_id" {
  value = module.user_pool.user_pool_id
}
output "client_ids" {
  value = module.user_pool.client_ids
}
```

### User pool only (no domain, no client)

```hcl
module "user_pool" {
  source = "./modules/user-pool"

  name          = "my-app-users"
  domain_prefix = null
  app_clients   = {}
}
```

### Profiles: basic hosted UI vs federated / confidential client

**Basic hosted UI** (default): one or more `app_clients` with `{}` or omitted per-client fields; module-level `callback_urls` / `logout_urls` / `allowed_oauth_flows` / `explicit_auth_flows` apply to every client. Clients use `generate_secret = false` and `supported_identity_providers = ["COGNITO"]` unless overridden.

**Federated / enterprise**: set `identity_providers` (map keyed by provider **name** as Cognito will register it), optional `user_pool_schema` for custom attributes used in IdP claim mapping, and per-client options such as `generate_secret = true`, `supported_identity_providers = ["COGNITO", "MySAMLProvider"]`, and optional per-client `callback_urls` / `logout_urls` / `explicit_auth_flows` / `allowed_oauth_flows`. For SAML metadata URLs where Cognito mutates `provider_details` after create, set `identity_provider_ignore_managed_metadata_keys = true` to ignore `ActiveEncryptionCertificate`, `SLORedirectBindingURI`, and `SSORedirectBindingURI` drift. Read confidential client secrets from the sensitive output **`client_secrets`**. Any workload that combines hosted UI, enterprise IdP, custom attributes, and token triggers (for example a Kubernetes dashboard using Cognito + SAML + a pre-token Lambda) fits this profile; keep variable names generic in your root module.

### Upgrade note (`app_clients` typing)

`app_clients` is now a typed `map(object({ ... }))` with **optional** fields and defaults, so `app_clients = { "web" = {} }` remains valid. Remove any extra keys previously tolerated under `map(any)` that are not part of the declared object shape, or Terraform will reject the configuration.

## Usage (cognito-trigger-lambda + pre token on user-pool)

Build the trigger function with **modules/cognito-trigger-lambda** (local zip or S3 object), then point **modules/user-pool** at its ARN and optionally create the Cognito invoke permission in the same apply graph.

**Deployment package:** pass **either** `filename` + `source_code_hash` **or** `s3_bucket` + `s3_key` (optional `s3_object_version`). **IAM:** pass `lambda_role_arn`, or omit it to create a role and attach `iam_role_managed_policy_arns` (defaults to `AWSLambdaBasicExecutionRole`).

```hcl
# Caller typically uses data "archive_file" to produce filename + source_code_hash.
module "pre_token_lambda" {
  source = "./modules/cognito-trigger-lambda"

  function_name = "my-app-pre-token"
  runtime       = "nodejs22.x"
  handler       = "index.handler"

  filename         = var.lambda_zip_path
  source_code_hash = var.lambda_zip_hash

  environment = { GROUP_RULES = jsonencode(var.group_rules) }
  tags          = var.tags
}

module "user_pool" {
  source = "./modules/user-pool"

  name          = "my-app-users"
  domain_prefix = "my-app-auth"
  app_clients   = { "web" = {} }

  callback_urls = ["https://myapp.example.com/callback"]
  logout_urls   = ["https://myapp.example.com/"]

  pre_token_generation_lambda_arn                   = module.pre_token_lambda.function_arn
  pre_token_generation_lambda_version               = "V2_0"
  create_pre_token_generation_lambda_permission     = true
  pre_token_generation_lambda_function_name         = module.pre_token_lambda.function_name

  tags = var.tags
}
```

**Apply order:** the user pool references the Lambda ARN; `aws_lambda_permission` depends on the pool. There is no Terraform cycle: create the Lambda first (submodule), then create/update the user pool with `lambda_config`, then the permission resource is created. If Cognito rejects invocations before the permission exists, ensure the pool update and permission are in the **same** apply (as above).

### Federated example (abbreviated)

```hcl
module "user_pool" {
  source = "./modules/user-pool"

  name          = "my-app-users"
  domain_prefix = "my-app-auth"

  identity_providers = {
    MySAMLProvider = {
      provider_type = "SAML"
      provider_details = {
        MetadataURL = "https://idp.example.com/metadata"
        IDPSignout    = "false"
      }
      attribute_mapping = {
        email = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
      }
    }
  }
  identity_provider_ignore_managed_metadata_keys = true

  user_pool_schema = [
    {
      name                = "groups"
      attribute_data_type = "String"
      mutable             = true
      string_attribute_constraints = {
        min_length = "0"
        max_length = "2048"
      }
    }
  ]

  app_clients = {
    web = {
      generate_secret              = true
      supported_identity_providers = ["COGNITO", "MySAMLProvider"]
    }
  }

  callback_urls = ["https://myapp.example.com/oidc-callback"]
  logout_urls   = ["https://myapp.example.com/"]

  tags = { Environment = "prod" }
}

# After apply: use sensitive output for client secrets
output "client_ids" {
  value = module.user_pool.client_ids
}
output "client_secrets" {
  value     = module.user_pool.client_secrets
  sensitive = true
}
output "idp_names" {
  value = module.user_pool.identity_provider_names
}
```

## Examples

- [examples/basic](examples/basic) – Full working demo: user pool with domain, app client, groups (`admin`, `readonly`), a demo user in `admin`, and a static site (S3 + CloudFront) so you can log in in the browser and see user and group details on the callback page. See [examples/basic/README.md](examples/basic/README.md) for usage.

## Running tests

Tests use Terraform’s native `terraform test` with **`mock_provider "aws"`** so **plan-only** runs do not need real AWS credentials.

```bash
cd tests/user-pool
terraform init
terraform test
```

```bash
cd tests/cognito-trigger-lambda
terraform init
terraform test
```

To exercise the same configurations against a real AWS account, remove the `mock_provider "aws" {}` blocks from the `*.tftest.hcl` files (or override providers) and run `terraform test` with valid credentials.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## License

See [LICENSE](LICENSE).
