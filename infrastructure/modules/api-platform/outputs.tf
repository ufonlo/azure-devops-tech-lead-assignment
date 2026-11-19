output "api_url" {
  value       = var.container_apps_enabled ? "https://${azurerm_container_app.api[0].ingress[0].fqdn}" : null
  description = "Public API URL, or null when Container Apps is disabled."
}

output "container_registry" {
  value       = azurerm_container_registry.this.login_server
  description = "ACR login server."
}

output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Key Vault resource ID."
}

