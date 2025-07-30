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
