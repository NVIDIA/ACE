
resource "azurerm_storage_account" "storage_account" {
  name                            = replace(var.name, "/\\W/", "")
  resource_group_name             = var.resource_group_name
  location                        = var.region
  account_tier                    = "Standard"
  account_replication_type        = var.replication_type
  allow_nested_items_to_be_public = false
  tags                            = var.additional_tags
}