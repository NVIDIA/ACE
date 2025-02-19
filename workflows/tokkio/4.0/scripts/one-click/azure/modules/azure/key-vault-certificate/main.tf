
resource "azurerm_key_vault_certificate" "certificate" {
  name         = var.name
  key_vault_id = var.key_vault_id
  certificate {
    contents = var.contents
    password = var.password
  }
  tags = var.additional_tags
}