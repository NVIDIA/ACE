provider "azurerm" {
  tenant_id       = var.provider_config.tenant_id
  subscription_id = var.provider_config.subscription_id
  client_id       = var.provider_config.client_id
  client_secret   = var.provider_config.client_secret
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}