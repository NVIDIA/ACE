
output "endpoint_id" {
  value = azurerm_cdn_endpoint.cdn_endpoint.id
}

output "endpoint_fqdn" {
  value = azurerm_cdn_endpoint.cdn_endpoint.fqdn
}