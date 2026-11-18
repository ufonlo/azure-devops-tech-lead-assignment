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

variable "container_image" {
  type        = string
  description = "Full container image reference. Production must use an immutable sha256 digest."

  validation {
    condition     = var.environment != "prod" || can(regex("@sha256:[0-9a-f]{64}$", var.container_image))
    error_message = "Production container_image must be pinned with @sha256:<64 lowercase hexadecimal characters>."
  }
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

variable "tags" {
  type        = map(string)
  description = "Additional Azure resource tags."
  default     = { project = "devops-tech-lead-assignment" }
}
