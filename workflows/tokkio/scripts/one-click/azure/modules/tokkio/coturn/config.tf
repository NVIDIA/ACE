
resource "azurerm_storage_container" "config_storage_container" {
  name                  = format("%s-coturn", var.name)
  storage_account_name  = var.base_config.config_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "coturn_server_env" {
  name                   = "coturn-server-env.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.config_storage_container.name
  type                   = "Block"
  source_content = templatefile("${path.module}/config/coturn-server-env.sh.tpl", {
    turnserver_realm    = var.turnserver_realm
    turnserver_username = var.turnserver_username
    turnserver_password = var.turnserver_password
  })
}

resource "azurerm_storage_blob" "setup_coturn_server" {
  name                   = "setup-coturn-server.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/setup-coturn-server.sh")
}

locals {
  config_scripts = [
    {
      exec = "source"
      name = azurerm_storage_blob.coturn_server_env.name
      hash = sha256(azurerm_storage_blob.coturn_server_env.source_content)
    },
    {
      exec = "bash"
      name = azurerm_storage_blob.setup_coturn_server.name
      hash = sha256(azurerm_storage_blob.setup_coturn_server.source_content)
    }
  ]
}