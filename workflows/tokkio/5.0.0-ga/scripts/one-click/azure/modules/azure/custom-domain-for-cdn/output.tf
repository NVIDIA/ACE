
output "custom_domain_fqdn" {
  value = azurerm_cdn_endpoint_custom_domain.custom_domain.host_name
}