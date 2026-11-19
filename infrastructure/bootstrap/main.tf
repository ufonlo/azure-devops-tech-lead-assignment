data "azurerm_subscription" "current" {}

data "azurerm_role_definition" "rbac_administrator" {
  name  = "Role Based Access Control Administrator"
  scope = data.azurerm_subscription.current.id
}

data "azurerm_role_definition" "acr_pull" {
  name  = "AcrPull"
  scope = data.azurerm_subscription.current.id
}

data "azurerm_role_definition" "key_vault_secrets_user" {
  name  = "Key Vault Secrets User"
  scope = data.azurerm_subscription.current.id
}

resource "azurerm_resource_provider_registration" "microsoft_app" {
  name = "Microsoft.App"
}

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
  for_each = var.environments

  name     = "rg-${var.project_name}-${each.key}"
  location = var.location
  tags     = merge(var.tags, { environment = each.key })
}

resource "azurerm_role_definition" "terraform_plan_reader" {
  name        = "api-platform Terraform Plan Reader"
  scope       = data.azurerm_subscription.current.id
  description = "Read Azure resources for Terraform plans, including Container Apps secrets required by the AzureRM provider refresh."

  permissions {
    actions = [
      "*/read",
      "Microsoft.App/containerApps/listSecrets/action",
    ]
    not_actions = []
  }

  assignable_scopes = [
    for resource_group in azurerm_resource_group.environment : resource_group.id
  ]
}

# GitHub-hosted runners use dynamic public IPs; Entra-only access and container-scoped RBAC are the compensating controls.
#trivy:ignore:AVD-AZU-0012
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

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "state" {
  for_each = var.environments

  name                  = "tfstate-${each.key}"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "plans" {
  name                  = "tfplans"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "plans" {
  storage_account_id = azurerm_storage_account.state.id

  rule {
    name    = "delete-expired-terraform-plans"
    enabled = true

    filters {
      prefix_match = ["${azurerm_storage_container.plans.name}/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 7
      }

      version {
        delete_after_days_since_creation = 7
      }
    }
  }
}

resource "azurerm_management_lock" "state" {
  name       = "protect-terraform-state"
  scope      = azurerm_storage_account.state.id
  lock_level = "CanNotDelete"
  notes      = "Protects the Terraform state storage account from accidental deletion."
}

locals {
  identities                  = toset(concat(["pr", "plan"], keys(var.environments)))
  github_repository_parts     = split("/", var.github_repository)
  github_immutable_repository = "${local.github_repository_parts[0]}@${var.github_owner_id}/${local.github_repository_parts[1]}@${var.github_repository_id}"
  federations = merge({
    pr = {
      identity = "pr"
      subject  = "repo:${local.github_immutable_repository}:pull_request"
    }
    plan-main = {
      identity = "plan"
      subject  = "repo:${local.github_immutable_repository}:ref:refs/heads/main"
    }
    }, {
    for environment, config in var.environments : environment => {
      identity = environment
      subject  = "repo:${local.github_immutable_repository}:environment:${config.github_environment}"
    }
  })

  delegated_role_ids = [
    basename(data.azurerm_role_definition.acr_pull.id),
    basename(data.azurerm_role_definition.key_vault_secrets_user.id),
  ]

  constrained_rbac_condition = "((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(", ", local.delegated_role_ids)}})) AND ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(", ", local.delegated_role_ids)}}))"
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

  name                      = "github-${each.key}"
  user_assigned_identity_id = azurerm_user_assigned_identity.github[each.value.identity].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = each.value.subject
}

resource "azurerm_role_assignment" "state_deployer" {
  for_each = var.environments

  scope                = azurerm_storage_container.state[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "state_operator" {
  for_each = {
    for pair in setproduct(var.state_operator_object_ids, keys(var.environments)) :
    "${pair[0]}-${pair[1]}" => {
      object_id   = pair[0]
      environment = pair[1]
    }
  }

  scope                = azurerm_storage_container.state[each.value.environment].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.object_id
}

resource "azurerm_role_assignment" "state_plan_reader" {
  for_each = {
    for pair in setproduct(["pr", "plan"], keys(var.environments)) :
    "${pair[0]}-${pair[1]}" => {
      identity    = pair[0]
      environment = pair[1]
    }
  }

  scope                = azurerm_storage_container.state[each.value.environment].id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.github[each.value.identity].principal_id
}

resource "azurerm_role_assignment" "plans_writer" {
  scope                = azurerm_storage_container.plans.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github["plan"].principal_id
}

resource "azurerm_role_assignment" "plans_reader" {
  for_each = {
    for environment, config in var.environments : environment => config
    if config.tfplans_reader
  }

  scope                = azurerm_storage_container.plans.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "pr_reader" {
  for_each = azurerm_resource_group.environment

  scope              = each.value.id
  role_definition_id = azurerm_role_definition.terraform_plan_reader.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.github["pr"].principal_id
}

resource "azurerm_role_assignment" "plan_reader" {
  for_each = azurerm_resource_group.environment

  scope              = each.value.id
  role_definition_id = azurerm_role_definition.terraform_plan_reader.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.github["plan"].principal_id
}

resource "azurerm_role_assignment" "deployer_contributor" {
  for_each = azurerm_resource_group.environment

  scope                = each.value.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github[each.key].principal_id
}

resource "azurerm_role_assignment" "deployer_rbac" {
  for_each = azurerm_resource_group.environment

  scope              = each.value.id
  role_definition_id = data.azurerm_role_definition.rbac_administrator.id
  principal_id       = azurerm_user_assigned_identity.github[each.key].principal_id
  condition_version  = "2.0"
  condition          = local.constrained_rbac_condition
}

