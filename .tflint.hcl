plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# Bootstrap state is protected by an Azure CanNotDelete lock and soft delete.
# Platform resources intentionally remain removable when an environment is retired.
rule "azurerm_resources_missing_prevent_destroy" {
  enabled = false
}
