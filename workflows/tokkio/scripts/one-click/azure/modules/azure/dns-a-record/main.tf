
data "azurerm_dns_zone" "dns_zone" {
  name = var.base_domain
}

resource "azurerm_dns_a_record" "a_record" {
  name                = var.name
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = data.azurerm_dns_zone.dns_zone.resource_group_name
  ttl                 = var.ttl
  records             = var.ip_addresses
  target_resource_id  = var.azure_resource_id
  tags                = var.additional_tags
}