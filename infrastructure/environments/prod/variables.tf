variable "subscription_id" {
  type = string
}

variable "project_name" {
  type    = string
  default = "api-platform"
}

variable "location" {
  type    = string
  default = "northeurope"
}

variable "container_image" {
  type    = string
  default = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "tags" {
  type    = map(string)
  default = { project = "devops-tech-lead-assignment" }
}

