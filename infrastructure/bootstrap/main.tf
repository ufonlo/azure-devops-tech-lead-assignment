data "azurerm_subscription" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "state" {
  name     = "rg-${var.project_name}-tfstate"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "environment" {
  for_each = toset(["dev", "prod"])

  name     = "rg-${var.project_name}-${each.key}"
  location = var.location
  tags     = merge(var.tags, { environment = each.key })
}

resource "azurerm_storage_account" "state" {
  name                            = "st${replace(var.project_name, "-", "")}${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = var.tags
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

locals {
  identities = toset(["plan", "dev", "prod"])
  federations = {
    plan-pr = {
      identity = "plan"
      subject  = "repo:${var.github_repository}:pull_request"
    }
    plan-main = {
      identity = "plan"
      subject  = "repo:${var.github_repository}:ref:refs/heads/main"
    }
    dev = {
      identity = "dev"
      subject  = "repo:${var.github_repository}:environment:development"
    }
    prod = {
      identity = "prod"
      subject  = "repo:${var.github_repository}:environment:production"
    }
  }
}

resource "azurerm_user_assigned_identity" "github" {
  for_each = local.identities

  name                = "id-gh-${var.project_name}-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.state.name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "github" {
  for_each = local.federations

  name                = "github-${each.key}"
  resource_group_name = azurerm_resource_group.state.name
  parent_id           = azurerm_user_assigned_identity.github[each.value.identity].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = each.value.subject
}

resource "azurerm_role_assignment" "state" {
  for_each = azurerm_user_assigned_identity.github

  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.principal_id
}

resource "azurerm_role_assignment" "plan_reader" {
  for_each = azurerm_resource_group.environment

  scope                = each.value.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.github["plan"].principal_id
}

resource "azurerm_role_assignment" "deployer_contributor" {
  for_each = azurerm_resource_group.environment

  scope                = each.value.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "deployer_rbac" {
  for_each = azurerm_resource_group.environment

  scope                = each.value.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

