variable "subscription_id" {
  type        = string
  description = "Azure subscription containing the platform environment."
}

variable "project_name" {
  type        = string
  description = "Short project name used in Azure resource names."
  default     = "api-platform"
}

variable "environment" {
  type        = string
  description = "Deployment environment name."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,10}[a-z0-9]$", var.environment))
    error_message = "environment must be 3-12 lowercase alphanumeric or hyphen characters, start with a letter, and end with an alphanumeric character."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the environment."
  default     = "northeurope"
}

variable "container_apps_location" {
  type        = string
  description = "Optional Azure region used only for the Container Apps managed environment. Defaults to location."
  default     = null
}

variable "container_image" {
  type        = string
  description = "Full container image reference. Environments that require immutable images must use a sha256 digest."

  validation {
    condition     = !var.require_pinned_image || can(regex("@sha256:[0-9a-f]{64}$", var.container_image))
    error_message = "container_image must be pinned with @sha256:<64 lowercase hexadecimal characters> when require_pinned_image is true."
  }
}

variable "require_pinned_image" {
  type        = bool
  description = "Require container_image to use an immutable sha256 digest for this environment."
  default     = true
}

variable "min_replicas" {
  type        = number
  description = "Minimum active replicas."
}

variable "max_replicas" {
  type        = number
  description = "Maximum active replicas."
}

variable "log_retention_days" {
  type        = number
  description = "Log Analytics retention in days."
}

variable "key_vault_operator_ip_ranges" {
  type        = list(string)
  description = "Public IPv4 addresses or CIDR ranges allowed to access the Key Vault data plane for operator tasks."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional Azure resource tags."
  default     = { project = "devops-tech-lead-assignment" }
}
