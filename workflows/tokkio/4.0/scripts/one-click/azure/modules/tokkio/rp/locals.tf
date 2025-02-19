
locals {
  name                                 = format("%s-rp", var.name)
  instance_public_ip_placeholder       = "INSTANCE_PUBLIC_IP_PLACEHOLDER"
  instance_public_ip_placeholder_regex = format("/%s/", local.instance_public_ip_placeholder)

  rp_vm_size_default              = "Standard_B2s_v2"
  rp_vm_size                      = var.rp_vm_size == null ? local.rp_vm_size_default : var.rp_vm_size
  rp_vm_data_disk_size_gb_default = 1024
  rp_vm_data_disk_size_gb         = var.rp_vm_data_disk_size_gb == null ? local.rp_vm_data_disk_size_gb_default : var.rp_vm_data_disk_size_gb

  rp_settings_defaults = {
    chart_org     = "nvidia"
    chart_team    = "ucs-ms"
    chart_name    = "rproxy"
    chart_version = "0.0.5"
    cns_settings = {
      cns_version = "11.0"
      cns_commit  = "1abe8a8e17c7a15adb8b2585481a3f69a53e51e2"
    }
  }
  rp_settings = var.rp_settings != null ? {
    chart_org     = coalesce(var.rp_settings.chart_org, local.rp_settings_defaults.chart_org)
    chart_team    = coalesce(var.rp_settings.chart_team, local.rp_settings_defaults.chart_team)
    chart_name    = coalesce(var.rp_settings.chart_name, local.rp_settings_defaults.chart_name)
    chart_version = coalesce(var.rp_settings.chart_version, local.rp_settings_defaults.chart_version)
    cns_settings = var.rp_settings["cns_settings"] != null ? {
      cns_version = var.rp_settings["cns_settings"]["cns_version"] != null ? var.rp_settings["cns_settings"]["cns_version"] : local.rp_settings_defaults["cns_settings"]["cns_version"]
      cns_commit  = var.rp_settings["cns_settings"]["cns_commit"] != null ? var.rp_settings["cns_settings"]["cns_commit"] : local.rp_settings_defaults["cns_settings"]["cns_commit"]
    } : local.rp_settings_defaults["cns_settings"]
  } : local.rp_settings_defaults
  chart_url = format(
    "https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz",
    local.rp_settings["chart_org"],
    local.rp_settings["chart_team"],
    local.rp_settings["chart_name"],
    local.rp_settings["chart_version"]
  )
  config_user_data_with_public_ip_placeholder = templatefile("${path.module}/user-data/user-data.sh.tpl", {
    config_storage_account         = var.base_config.config_storage_account.name
    config_storage_container       = azurerm_storage_container.env_config_storage_container.name
    config_access_client_id        = var.base_config.config_storage_account.reader_identity.client_id
    config_scripts                 = local.config_scripts
    instance_public_ip_placeholder = local.instance_public_ip_placeholder
  })
  rp_vm_image_version_defaults = "latest"
  rp_vm_image_version          = var.rp_vm_image_version == null ? local.rp_vm_image_version_defaults : var.rp_vm_image_version
  vm_details = {
    size                   = local.rp_vm_size
    zone                   = "1"
    admin_username         = "ubuntu"
    accelerated_networking = false
    image_details = {
      publisher = "canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = local.rp_vm_image_version
    }
    os_disk_details = {
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 64
    }
    data_disk_details = [
      {
        name                 = "data-disk-0"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = local.rp_vm_data_disk_size_gb
        lun                  = 0
        caching              = "ReadOnly"
      }
    ]
    identity = {
      identity_ids = [
        var.base_config.config_storage_account.reader_identity.id
      ]
      type = "UserAssigned"
    }
  }
}