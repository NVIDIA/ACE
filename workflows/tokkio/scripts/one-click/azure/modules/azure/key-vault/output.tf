
output "id" {
  value = azurerm_key_vault.key_vault.id
}

output "name" {
  value = azurerm_key_vault.key_vault.name
}

output "access_policy" {
  value = { for access_policy in var.access_policies : azurerm_key_vault_access_policy.access_policy[access_policy.identifier].id => access_policy.object_id }
}