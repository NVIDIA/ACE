
resource "azurerm_user_assigned_identity" "config_reader" {
  name                = format("%s-config-reader", var.name)
  resource_group_name = module.resource_group.name
  location            = var.region
}

module "config_storage_account" {
  source              = "../../azure/storage-account"
  name                = format("%s-cf", var.name)
  resource_group_name = module.resource_group.name
  region              = var.region
}

resource "azurerm_role_assignment" "config_reader_access" {
  scope                = module.config_storage_account.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.config_reader.principal_id
}