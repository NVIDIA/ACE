
resource "azurerm_storage_container" "env_config_storage_container" {
  name                  = format("%s-rp", var.name)
  storage_account_name  = var.base_config.config_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "mount_data_disk" {
  name                   = "mount-data-disk.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/mount-data-disk.sh")
}

resource "azurerm_storage_blob" "install_cns" {
  name                   = "install-cns.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/install-cns.sh")
}

resource "azurerm_storage_blob" "rp_env" {
  name                   = "rp-env.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content = templatefile("${path.module}/config/rp-env.sh.tpl", {
    ngc_api_key = var.ngc_api_key
    chart_url   = local.chart_url
    cns_commit  = local.rp_settings.cns_settings.cns_commit
    cns_version = local.rp_settings.cns_settings.cns_version
  })
}

resource "azurerm_storage_blob" "apply_rp_secrets" {
  name                   = "apply-rp-secrets.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/apply-rp-secrets.sh")
}

resource "azurerm_storage_blob" "install_rp_chart" {
  name                   = "install-rp-chart.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/install-rp-chart.sh")
}

locals {
  config_scripts = [
    {
      exec = "bash"
      name = azurerm_storage_blob.mount_data_disk.name
      hash = sha256(azurerm_storage_blob.mount_data_disk.source_content)
    },
    {
      exec = "source"
      name = azurerm_storage_blob.rp_env.name
      hash = sha256(azurerm_storage_blob.rp_env.source_content)
    },
    {
      exec = "bash"
      name = azurerm_storage_blob.install_cns.name
      hash = sha256(azurerm_storage_blob.install_cns.source_content)
    },
    {
      exec = "bash"
      name = azurerm_storage_blob.apply_rp_secrets.name
      hash = sha256(azurerm_storage_blob.apply_rp_secrets.source_content)
    },
    {
      exec = "bash"
      name = azurerm_storage_blob.install_rp_chart.name
      hash = sha256(azurerm_storage_blob.install_rp_chart.source_content)
    }
  ]
}