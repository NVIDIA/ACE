
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.region
  tags     = var.additional_tags
}