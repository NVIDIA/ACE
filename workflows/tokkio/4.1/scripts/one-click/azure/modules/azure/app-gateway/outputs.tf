output "public_ip" {
  value = {
    for frontend_ip_configuration in var.frontend_ip_configurations :
    frontend_ip_configuration.public_ip_address["name"] =>
    azurerm_public_ip.public_ip[frontend_ip_configuration.public_ip_address["name"]].ip_address
    if frontend_ip_configuration.public_ip_address != null
  }
}