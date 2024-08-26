
data "azurerm_dns_zone" "dns_zone" {
  name = var.dns_and_certs_configs.dns_zone
}

data "azurerm_app_service_certificate_order" "wildcard_certificate" {
  name                = var.dns_and_certs_configs.wildcard_cert
  resource_group_name = var.dns_and_certs_configs.resource_group
}

data "azurerm_key_vault_secret" "wildcard_certificate_secret" {
  key_vault_id = data.azurerm_app_service_certificate_order.wildcard_certificate.certificates[0].key_vault_id
  name         = data.azurerm_app_service_certificate_order.wildcard_certificate.certificates[0].key_vault_secret_name
}