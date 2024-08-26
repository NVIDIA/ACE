
locals {
  name                                 = format("%s-coturn", var.name)
  instance_public_ip_placeholder       = "INSTANCE_PUBLIC_IP_PLACEHOLDER"
  instance_public_ip_placeholder_regex = format("/%s/", local.instance_public_ip_placeholder)
  config_user_data_with_public_ip_placeholder = templatefile("${path.module}/user-data/user-data.sh.tpl", {
    config_storage_account         = var.base_config.config_storage_account.name
    config_storage_container       = azurerm_storage_container.config_storage_container.name
    config_access_client_id        = var.base_config.config_storage_account.reader_identity.client_id
    config_scripts                 = local.config_scripts
    instance_public_ip_placeholder = local.instance_public_ip_placeholder
  })
  coturn_vm_image_version_defaults = "latest"
  coturn_vm_image_version          = var.coturn_vm_image_version == null ? local.coturn_vm_image_version_defaults : var.coturn_vm_image_version
  vm_details = {
    size                   = "Standard_B2s"
    zone                   = "1"
    admin_username         = "ubuntu"
    accelerated_networking = false
    image_details = {
      publisher = "canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = local.coturn_vm_image_version
    }
    os_disk_details = {
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 30
    }
    data_disk_details = []
    identity = {
      identity_ids = [
        var.base_config.config_storage_account.reader_identity.id
      ]
      type = "UserAssigned"
    }
  }
}