# terraform-aws-cognito

Terraform modules for AWS Cognito. The repository uses a multi-module layout so you can use only what you need.

## Layout

- **modules/user-pool** – Cognito User Pool with optional domain (hosted UI) and optional app clients. Use this for authentication (sign-up, sign-in, JWT).
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

## Examples

- [examples/basic](examples/basic) – Full working demo: user pool with domain, app client, groups (`admin`, `readonly`), a demo user in `admin`, and a static site (S3 + CloudFront) so you can log in in the browser and see user and group details on the callback page. See [examples/basic/README.md](examples/basic/README.md) for usage.

## Running tests

Tests live under `tests/user-pool/` and use Terraform's native test (plan-only by default). AWS credentials are required to run them.

```bash
cd tests/user-pool
terraform init
terraform test
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## License

See [LICENSE](LICENSE).
