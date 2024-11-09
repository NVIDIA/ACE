output "id" {
  value = azurerm_linux_virtual_machine.default.id
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.default.public_ip_address
}

output "private_ip" {
  value = azurerm_linux_virtual_machine.default.private_ip_address
}