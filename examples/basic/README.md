# Basic example

Working demo that creates a Cognito User Pool with hosted UI, two groups (`admin`, `readonly`), one app client, a demo user in the `admin` group, and a static site (S3 + CloudFront) so you can log in in the browser and see your user and group details.

## What it creates

- **User pool** – Email as username, password policy, hosted UI domain
- **App client** – Public client, implicit flow, callback/logout URLs pointing at the demo site
- **Groups** – `admin` (precedence 1) and `readonly` (precedence 2)
- **Demo user** – One user (email from variable), system-generated temporary password, assigned to `admin`
- **Static site** – S3 bucket (private) behind CloudFront (HTTPS). Index page has “Login with Cognito”; callback page shows user sub, email, and `cognito:groups` from the ID token

## Requirements

- Terraform >= 1.0
- AWS provider >= 5.0
- Random provider >= 3.0
- AWS credentials (e.g. `AWS_PROFILE` or env vars)

## Usage

1. **Optional:** Copy and edit tfvars for the demo user email:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit demo_user_username if desired (default: demo@example.com)
   ```

2. **Apply:**

   ```bash
   terraform init
   terraform apply
   ```

3. **Open the demo:** Use the `demo_site_url` output in your browser.

4. **Log in:** Click “Login with Cognito”, sign in with `demo_user` and `demo_password` (from outputs). Use `terraform output -raw demo_password` to get the password.

5. **Callback page** shows your user (sub, email) and groups (e.g. `admin`).

## Outputs

| Name            | Description                    |
|-----------------|--------------------------------|
| `demo_site_url` | URL to open for the demo       |
| `demo_user`     | Username (email) for login     |
| `demo_password` | Temporary password (sensitive) |
| `hosted_ui_url` | Cognito Hosted UI base URL     |

## Inputs

| Name                 | Description                    | Default           |
|----------------------|--------------------------------|-------------------|
| `demo_user_username` | Email for the demo Cognito user| `demo@example.com`|

## Notes

- CloudFront distribution can take 5–15 minutes to deploy on first apply.
- The demo user password is generated once; store it (e.g. from `terraform output -raw demo_password`) for login. Password is not emailed (`message_action = "SUPPRESS"`).
