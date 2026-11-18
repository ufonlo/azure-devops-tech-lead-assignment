output "api_url" {
  value       = "https://${azurerm_container_app.api.latest_revision_fqdn}"
  description = "Public API URL."
}

output "container_registry" {
  value       = azurerm_container_registry.this.login_server
  description = "ACR login server."
}

output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Key Vault resource ID."
}

