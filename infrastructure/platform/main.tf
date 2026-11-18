module "api_platform" {
  source = "../modules/api-platform"

  project_name                 = var.project_name
  environment                  = var.environment
  resource_group_name          = "rg-${var.project_name}-${var.environment}"
  location                     = var.location
  container_image              = var.container_image
  min_replicas                 = var.min_replicas
  max_replicas                 = var.max_replicas
  log_retention_days           = var.log_retention_days
  key_vault_operator_ip_ranges = var.key_vault_operator_ip_ranges
  tags                         = var.tags
}

output "api_url" {
  value = module.api_platform.api_url
}
