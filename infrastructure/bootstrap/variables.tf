variable "subscription_id" {
  description = "Personal Azure subscription ID used for the assignment."
  type        = string
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "northeurope"
}

variable "project_name" {
  description = "Short lowercase project name used in resource names."
  type        = string
  default     = "api-platform"
}

variable "github_repository" {
  description = "GitHub repository in owner/name form."
  type        = string
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub owner ID used in OIDC subjects."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "github_owner_id must contain digits only."
  }
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID used in OIDC subjects."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "github_repository_id must contain digits only."
  }
}

variable "environments" {
  description = "Deployment environments keyed by their stable Terraform resource key."
  type = map(object({
    github_environment = string
    tfplans_reader     = optional(bool, false)
  }))
  default = {
    dev = {
      github_environment = "development"
      tfplans_reader     = true
    }
    prod = {
      github_environment = "production"
      tfplans_reader     = true
    }
  }
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    managed-by = "terraform"
    project    = "devops-tech-lead-assignment"
  }
}

