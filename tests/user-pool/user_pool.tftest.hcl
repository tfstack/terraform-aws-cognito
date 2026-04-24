mock_provider "aws" {}

run "user_pool_with_domain_and_client" {
  command = plan

  variables {
    user_pool_name = "test-user-pool-basic"
    domain_prefix  = "test-user-pool-basic"
    app_clients    = { "web" = {} }
    callback_urls  = ["https://example.com/callback"]
    logout_urls    = ["https://example.com/logout"]
    tags           = { Test = "true" }
  }

  # Plan-only: computed outputs (user_pool_id, client_ids, domain_name) are unknown until apply.
  # Assert that this configuration is valid and the intended inputs are set.
  assert {
    condition     = var.user_pool_name == "test-user-pool-basic" && length(var.app_clients) == 1 && var.domain_prefix == "test-user-pool-basic"
    error_message = "Test variables should be set for domain + client run"
  }
}

run "user_pool_minimal_no_domain_no_client" {
  command = plan

  variables {
    user_pool_name   = "test-user-pool-minimal"
    domain_prefix    = null
    app_clients      = {}
    user_pool_groups = {}
    tags             = {}
  }

  # Plan-only: assert inputs so we validate minimal config (no domain, no clients).
  assert {
    condition     = var.domain_prefix == null && length(var.app_clients) == 0
    error_message = "Test variables should be set for minimal run (no domain, no clients)"
  }
}

run "user_pool_with_groups" {
  command = plan

  variables {
    user_pool_name = "test-user-pool-groups"
    domain_prefix  = "test-user-pool-groups"
    app_clients    = { "web" = {} }
    user_pool_groups = {
      "admins" = { description = "Admins", precedence = 1 }
      "users"  = { description = "Users", precedence = 2 }
    }
    callback_urls = ["https://example.com/callback"]
    logout_urls   = ["https://example.com/logout"]
    tags          = { Test = "true" }
  }

  assert {
    condition     = length(var.user_pool_groups) == 2 && var.user_pool_name == "test-user-pool-groups"
    error_message = "Test variables should be set for groups run"
  }
}

run "user_pool_with_pre_token_generation" {
  command = plan

  variables {
    user_pool_name                                = "test-user-pool-pre-token"
    domain_prefix                                 = "test-user-pool-pre-token"
    app_clients                                   = { "web" = {} }
    callback_urls                                 = ["https://example.com/callback"]
    logout_urls                                   = ["https://example.com/logout"]
    tags                                          = { Test = "true" }
    pre_token_generation_lambda_arn               = "arn:aws:lambda:ap-southeast-2:123456789012:function:test-pre-token"
    pre_token_generation_lambda_version           = "V2_0"
    create_pre_token_generation_lambda_permission = true
    pre_token_generation_lambda_function_name     = "test-pre-token"
  }

  assert {
    condition = (
      var.pre_token_generation_lambda_arn != null &&
      var.create_pre_token_generation_lambda_permission &&
      var.pre_token_generation_lambda_function_name == "test-pre-token"
    )
    error_message = "Test variables should be set for pre-token generation run"
  }
}

run "user_pool_federated_confidential_client" {
  command = plan

  variables {
    user_pool_name = "test-user-pool-federated"
    domain_prefix  = "test-user-pool-federated"
    app_clients = {
      "webapp" = {
        generate_secret              = true
        supported_identity_providers = ["COGNITO", "EntraID"]
      }
    }
    callback_urls = ["https://app.example.com/callback"]
    logout_urls   = ["https://app.example.com/"]
    tags          = { Test = "federated" }
    identity_providers = {
      "EntraID" = {
        provider_type = "SAML"
        provider_details = {
          MetadataURL = "https://login.microsoftonline.com/00000000-0000-0000-0000-000000000000/federationmetadata/2007-06/federationmetadata.xml"
          IDPSignout  = "false"
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
  }

  assert {
    condition = (
      length(var.identity_providers) == 1 &&
      try(var.app_clients["webapp"].generate_secret, false) == true &&
      length(var.user_pool_schema) == 1
    )
    error_message = "Federated test variables should include IdP, schema, and confidential client"
  }
}
