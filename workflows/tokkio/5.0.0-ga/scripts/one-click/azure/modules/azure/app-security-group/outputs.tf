output "application_security_group" {
  value = {
    for k, v in azurerm_application_security_group.default : k => v.id
  }
}