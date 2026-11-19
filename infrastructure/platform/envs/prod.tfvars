environment            = "prod"
location               = "northeurope"
container_apps_enabled = false
container_image        = "mcr.microsoft.com/azuredocs/containerapps-helloworld@sha256:e9b3e7c34664c7cffd7144864b0e4eec369bfde80068f9095dc63b37058bec48"
require_pinned_image   = true
min_replicas           = 1
max_replicas           = 5
log_retention_days     = 90
