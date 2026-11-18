module "api_platform" {
  source = "../../modules/api-platform"

  project_name        = var.project_name
  environment         = "prod"
  resource_group_name = "rg-${var.project_name}-prod"
  location            = var.location
  container_image     = var.container_image
  min_replicas        = 1
  max_replicas        = 5
  log_retention_days  = 90
  tags                = var.tags
}

output "api_url" {
  value = module.api_platform.api_url
}

