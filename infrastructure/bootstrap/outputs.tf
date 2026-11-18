output "backend" {
  description = "Values used in environment backend.hcl files."
  value = {
    resource_group_name  = azurerm_resource_group.state.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.state.name
  }
}

output "github_oidc" {
  description = "Non-secret repository variables for GitHub Actions."
  value = {
    tenant_id       = data.azurerm_subscription.current.tenant_id
    subscription_id = data.azurerm_subscription.current.subscription_id
    plan_client_id  = azurerm_user_assigned_identity.github["plan"].client_id
    dev_client_id   = azurerm_user_assigned_identity.github["dev"].client_id
    prod_client_id  = azurerm_user_assigned_identity.github["prod"].client_id
  }
}

