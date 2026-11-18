module "api_platform" {
  source = "../../modules/api-platform"

  project_name        = var.project_name
  environment         = "dev"
  resource_group_name = "rg-${var.project_name}-dev"
  location            = var.location
  container_image     = var.container_image
  min_replicas        = 0
  max_replicas        = 2
  log_retention_days  = 30
  tags                = var.tags
}

output "api_url" {
  value = module.api_platform.api_url
}

