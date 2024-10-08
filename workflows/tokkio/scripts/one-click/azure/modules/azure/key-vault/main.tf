
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.region
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = var.enable_rbac_authorization
  tags                      = var.additional_tags
}

resource "azurerm_key_vault_access_policy" "access_policy" {
  for_each                = { for access_policy in var.access_policies : access_policy.identifier => access_policy }
  key_vault_id            = azurerm_key_vault.key_vault.id
  tenant_id               = each.value["tenant_id"]
  object_id               = each.value["object_id"]
  certificate_permissions = each.value["certificate_permissions"]
  key_permissions         = each.value["key_permissions"]
  secret_permissions      = each.value["secret_permissions"]
  storage_permissions     = each.value["storage_permissions"]
}