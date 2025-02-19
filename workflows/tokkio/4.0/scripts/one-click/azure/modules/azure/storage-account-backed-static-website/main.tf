
resource "azurerm_storage_account" "storage_account" {
  name                            = replace(var.name, "/\\W/", "")
  resource_group_name             = var.resource_group_name
  location                        = var.region
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  static_website {
    index_document     = var.index_document
    error_404_document = var.error_404_document
  }
  tags = var.additional_tags
}