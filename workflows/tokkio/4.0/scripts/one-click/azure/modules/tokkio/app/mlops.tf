
data "azurerm_storage_account" "mlops_storage_account" {
  count               = local.api_settings.mlops == null ? 0 : 1
  name                = local.api_settings.mlops.storage_account
  resource_group_name = local.api_settings.mlops.resource_group
}

data "azurerm_storage_container" "mlops_storage_container" {
  count                = local.api_settings.mlops == null ? 0 : 1
  name                 = local.api_settings.mlops.storage_container
  storage_account_name = data.azurerm_storage_account.mlops_storage_account[count.index].name
}