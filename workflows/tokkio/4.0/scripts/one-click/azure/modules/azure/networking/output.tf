
output "region" {
  value = azurerm_virtual_network.virtual_network.location
}

output "virtual_network_id" {
  value = azurerm_virtual_network.virtual_network.id
}

output "subnet_ids" {
  value = { for subnet in var.subnet_details : subnet.identifier => azurerm_subnet.subnet[subnet.identifier].id }
}