variable "project_name" {
  type        = string
  description = "Short project name."
}

variable "environment" {
  type        = string
  description = "Deployment environment."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Pre-created environment resource group."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "container_image" {
  type        = string
  description = "Full container image reference. Use an immutable digest in production."
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "container_port" {
  type        = number
  description = "Application listening port."
  default     = 80
}

variable "min_replicas" {
  type        = number
  description = "Minimum active replicas."
  default     = 0
}

variable "max_replicas" {
  type        = number
  description = "Maximum active replicas."
  default     = 3
}

variable "log_retention_days" {
  type        = number
  description = "Log Analytics retention."
  default     = 30
}

variable "key_vault_secret_uris" {
  type        = map(string)
  description = "Map of Container Apps secret name to versionless Key Vault secret URI. Values are references, never secret values."
  default     = {}
}

variable "secret_environment_variables" {
  type        = map(string)
  description = "Map of environment variable name to a key in key_vault_secret_uris."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}

