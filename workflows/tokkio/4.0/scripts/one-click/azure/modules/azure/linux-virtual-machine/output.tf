
output "public_ip" {
  value = one(azurerm_public_ip.public_ip.*.ip_address)
}

output "private_ip" {
  value = azurerm_network_interface.network_interface.private_ip_address
}

output "network_interface_id" {
  value = azurerm_network_interface.network_interface.id
}

output "ip_configuration_name" {
  value = azurerm_network_interface.network_interface.ip_configuration[0].name
}