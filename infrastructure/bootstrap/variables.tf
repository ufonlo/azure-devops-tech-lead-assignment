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

