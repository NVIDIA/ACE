
resource "azurerm_cdn_profile" "cdn_profile" {
  name                = var.cdn_profile_name
  resource_group_name = var.resource_group_name
  location            = "global"
  sku                 = "Standard_Microsoft"
  tags                = var.additional_tags
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = var.cdn_endpoint_name
  resource_group_name = var.resource_group_name
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  location            = azurerm_cdn_profile.cdn_profile.location
  origin_host_header  = var.target_host_name
  origin {
    name      = replace(var.target_host_name, ".", "-")
    host_name = var.target_host_name
  }
}