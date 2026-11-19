environment          = "dev"
location             = "northeurope"
container_image      = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
require_pinned_image = false
min_replicas         = 0
max_replicas         = 2
log_retention_days   = 30
