resource "azurerm_public_ip" "external" {
  count               = var.attach_public_ip && (var.public_ip_address_id == null) ? 1 : 0
  name                = format("%s-nic-ext", var.name)
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zone == null ? null : [var.zone]
}

# resource "azurerm_network_interface" "external" {
#   count               = var.attach_public_ip ? 1 : 0
#   name                = format("%s-nic-ext", var.name)
#   resource_group_name = var.resource_group_name
#   location            = var.location

#   ip_configuration {
#     name                          = "primary"
#     subnet_id                     = var.subnet_id
#     private_ip_address_allocation = "Dynamic"
#     primary                       = true
#     public_ip_address_id          = coalesce(var.public_ip_address_id, one(azurerm_public_ip.external[*].id))
#   }
# }

resource "azurerm_network_interface" "internal" {
  name                = format("%s-nic-int", var.name)
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.attach_public_ip ? coalesce(var.public_ip_address_id, one(azurerm_public_ip.external[*].id)) : null
  }
}

resource "azurerm_network_interface_security_group_association" "default" {
  count                     = length(var.network_security_group_ids)
  network_interface_id      = azurerm_network_interface.internal.id
  network_security_group_id = element(var.network_security_group_ids, count.index)
}

resource "azurerm_network_interface_application_security_group_association" "default" {
  count                         = length(var.application_security_group_ids)
  network_interface_id          = azurerm_network_interface.internal.id
  application_security_group_id = element(var.application_security_group_ids, count.index)
}

resource "azurerm_linux_virtual_machine" "default" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  admin_username             = var.admin_username
  encryption_at_host_enabled = var.encryption_at_host_enabled
  size                       = var.size
  zone                       = var.zone
  tags                       = var.tags

  custom_data = var.custom_data

  #network_interface_ids = var.attach_public_ip ? [azurerm_network_interface.external[0].id, azurerm_network_interface.internal.id] : [azurerm_network_interface.internal.id]
  network_interface_ids = [azurerm_network_interface.internal.id]
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      identity_ids = identity.value["identity_ids"]
      type         = identity.value["type"]
    }
  }

  depends_on = [
    azurerm_network_interface_security_group_association.default,
    azurerm_network_interface_application_security_group_association.default
  ]
}

resource "azurerm_managed_disk" "data_disk" {
  for_each             = { for data_disk in var.data_disk_details : data_disk.name => data_disk }
  name                 = format("%s-%s", var.name, each.key)
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value["storage_account_type"]
  create_option        = "Empty"
  disk_size_gb         = each.value["disk_size_gb"]
  zone                 = var.zone
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  for_each           = { for data_disk in var.data_disk_details : data_disk.name => data_disk }
  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.default.id
  lun                = each.value["lun"]
  caching            = each.value["caching"]
}