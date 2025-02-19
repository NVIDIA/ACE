
resource "azurerm_public_ip" "public_ip" {
  count               = var.include_public_ip ? 1 : 0
  name                = var.name
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.additional_tags
  zones               = [var.zone]
}

resource "azurerm_network_interface" "network_interface" {
  name                          = var.name
  location                      = var.region
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.accelerated_networking
  ip_configuration {
    name                          = var.name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = one(azurerm_public_ip.public_ip.*.id)
  }
  tags = var.additional_tags
}

resource "azurerm_linux_virtual_machine" "virtual_machine" {
  name                  = var.name
  location              = var.region
  resource_group_name   = var.resource_group_name
  size                  = var.size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.network_interface.id]
  zone                  = var.zone
  custom_data           = var.user_data_with_public_ip_placeholder == null ? var.user_data : base64encode(replace(var.user_data_with_public_ip_placeholder, var.user_data_public_ip_placeholder_regex, one(azurerm_public_ip.public_ip.*.ip_address)))
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_details.storage_account_type
    disk_size_gb         = var.os_disk_details.disk_size_gb
  }
  source_image_reference {
    publisher = var.image_details.publisher
    offer     = var.image_details.offer
    sku       = var.image_details.sku
    version   = var.image_details.version
  }
  boot_diagnostics {}
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      identity_ids = identity.value["identity_ids"]
      type         = identity.value["type"]
    }
  }
  tags = var.additional_tags
}

resource "azurerm_managed_disk" "data_disk" {
  for_each             = { for data_disk in var.data_disk_details : data_disk.name => data_disk }
  name                 = format("%s-%s", var.name, each.key)
  location             = var.region
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value["storage_account_type"]
  create_option        = "Empty"
  disk_size_gb         = each.value["disk_size_gb"]
  zone                 = var.zone
  tags                 = var.additional_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  for_each           = { for data_disk in var.data_disk_details : data_disk.name => data_disk }
  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.virtual_machine.id
  lun                = each.value["lun"]
  caching            = each.value["caching"]
}