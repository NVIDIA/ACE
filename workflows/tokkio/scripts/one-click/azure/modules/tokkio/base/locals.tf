
module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = var.virtual_network_address_space
  networks = [
    {
      name     = local.bastion_subnet_identifier
      new_bits = 3
    },
    {
      name     = local.app_gw_subnet_identifier
      new_bits = 3
    },
    {
      name     = local.coturn_subnet_identifier
      new_bits = 3
    },
    {
      name     = local.rp_subnet_identifier
      new_bits = 3
    },
    {
      name     = local.app_api_subnet_identifier
      new_bits = 1
    }
  ]
}

locals {
  bastion_subnet_identifier = "public-subnet-1"
  coturn_subnet_identifier  = "public-subnet-2"
  app_gw_subnet_identifier  = "public-subnet-3"
  rp_subnet_identifier      = "public-subnet-4"
  app_api_subnet_identifier = "private-subnet-1"
  bastion_nsg_identifier    = "bastion-nsg"
  coturn_nsg_identifier     = "coturn-nsg"
  app_gw_nsg_identifier     = "app-gw-nsg"
  rp_nsg_identifier         = "rp-nsg"
  app_api_nsg_identifier    = "private-nsg"
  subnet_details = [
    {
      identifier            = local.bastion_subnet_identifier
      address_prefix        = module.subnet_addrs.network_cidr_blocks[local.bastion_subnet_identifier]
      type                  = "public"
      service_endpoints     = []
      nsg_identifier        = local.bastion_nsg_identifier
      associate_nat_gateway = true
    },
    {
      identifier            = local.coturn_subnet_identifier
      address_prefix        = module.subnet_addrs.network_cidr_blocks[local.coturn_subnet_identifier]
      type                  = "public"
      service_endpoints     = []
      nsg_identifier        = local.coturn_nsg_identifier
      associate_nat_gateway = true
    },
    {
      identifier            = local.app_gw_subnet_identifier
      address_prefix        = module.subnet_addrs.network_cidr_blocks[local.app_gw_subnet_identifier]
      type                  = "public"
      service_endpoints     = []
      nsg_identifier        = local.app_gw_nsg_identifier
      associate_nat_gateway = true
    },
    {
      identifier            = local.rp_subnet_identifier
      address_prefix        = module.subnet_addrs.network_cidr_blocks[local.rp_subnet_identifier]
      type                  = "public"
      service_endpoints     = ["Microsoft.KeyVault"]
      nsg_identifier        = local.rp_nsg_identifier
      associate_nat_gateway = false
    },
    {
      identifier            = local.app_api_subnet_identifier
      address_prefix        = module.subnet_addrs.network_cidr_blocks[local.app_api_subnet_identifier]
      type                  = "private"
      service_endpoints     = []
      nsg_identifier        = local.app_api_nsg_identifier
      associate_nat_gateway = true
    }
  ]
  network_security_groups = [
    {
      identifier = local.bastion_nsg_identifier
    },
    {
      identifier = local.coturn_nsg_identifier
    },
    {
      identifier = local.app_gw_nsg_identifier
    },
    {
      identifier = local.rp_nsg_identifier
    },
    {
      identifier = local.app_api_nsg_identifier
    }
  ]
  network_security_rules = [
    {
      nsg_identifier               = local.bastion_nsg_identifier
      name                         = "AllowSSHInbound"
      priority                     = 100
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      source_port_ranges           = null
      destination_port_range       = "22"
      destination_port_ranges      = null
      source_address_prefix        = null
      source_address_prefixes      = var.dev_source_address_prefixes
      destination_address_prefix   = "*"
      destination_address_prefixes = null
      include_nat_as_source        = false
    },
    {
      nsg_identifier               = local.coturn_nsg_identifier
      name                         = "AllowTurnTCPInbound"
      priority                     = 100
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      source_port_ranges           = null
      destination_port_range       = "3478"
      destination_port_ranges      = null
      source_address_prefix        = null
      source_address_prefixes      = var.user_source_address_prefixes
      destination_address_prefix   = "*"
      destination_address_prefixes = null
      include_nat_as_source        = true
    },
    {
      nsg_identifier               = local.coturn_nsg_identifier
      name                         = "AllowTurnUDPInbound"
      priority                     = 110
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Udp"
      source_port_range            = "*"
      source_port_ranges           = null
      destination_port_range       = "3478"
      destination_port_ranges      = null
      source_address_prefix        = null
      source_address_prefixes      = var.user_source_address_prefixes
      destination_address_prefix   = "*"
      destination_address_prefixes = null
      include_nat_as_source        = true
    },
    {
      nsg_identifier               = local.coturn_nsg_identifier
      name                         = "AllowTurnUDPRangeInbound"
      priority                     = 120
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Udp"
      source_port_range            = "*"
      source_port_ranges           = null
      destination_port_range       = "49152-65535"
      destination_port_ranges      = null
      source_address_prefix        = null
      source_address_prefixes      = var.user_source_address_prefixes
      destination_address_prefix   = "*"
      destination_address_prefixes = null
      include_nat_as_source        = true
    },
    {
      nsg_identifier               = local.coturn_nsg_identifier
      name                         = "AllowSSHInbound"
      priority                     = 130
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      source_port_ranges           = null
      destination_port_range       = "22"
      destination_port_ranges      = null
      source_address_prefix        = null
      source_address_prefixes      = var.dev_source_address_prefixes
      destination_address_prefix   = "*"
      destination_address_prefixes = null
      include_nat_as_source        = false
    },
    {
      nsg_identifier               = local.app_gw_nsg_identifier
      name                         = "AllowHTTPSInbound"
      priority                     = 100
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      source_port_ranges           = null
      destination_port_range       = "443"
      destination_port_ranges      = null
      source_address_prefix        = null
      source_address_prefixes      = var.user_source_address_prefixes
      destination_address_prefix   = "*"
      destination_address_prefixes = null
      include_nat_as_source        = false
    },
    {
      nsg_identifier               = local.app_gw_nsg_identifier
      name                         = "AllowGatewayManagerInbound"
      priority                     = 110
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "*"
      source_port_range            = "*"
      source_port_ranges           = null
      destination_port_range       = "65200-65535"
      destination_port_ranges      = null
      source_address_prefix        = "GatewayManager"
      source_address_prefixes      = null
      destination_address_prefix   = "*"
      destination_address_prefixes = null
      include_nat_as_source        = false
    },
    {
      nsg_identifier               = local.rp_nsg_identifier
      name                         = "AllowClientUDPStreamingInbound"
      priority                     = 110
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Udp"
      source_port_range            = "*"
      source_port_ranges           = null
      destination_port_range       = "10000-20000"
      destination_port_ranges      = null
      source_address_prefix        = null
      source_address_prefixes      = var.user_source_address_prefixes
      destination_address_prefix   = "*"
      destination_address_prefixes = null
      include_nat_as_source        = true
    }
  ]

  bastion_vm_image_version_defaults = "latest"
  bastion_vm_image_version          = var.bastion_vm_image_version == null ? local.bastion_vm_image_version_defaults : var.bastion_vm_image_version
  bastion_vm_details = {
    subnet_identifier      = local.bastion_subnet_identifier
    size                   = "Standard_B1ls"
    zone                   = "1"
    admin_username         = "ubuntu"
    accelerated_networking = false
    image_details = {
      publisher = "canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = local.bastion_vm_image_version
    }
    os_disk_details = {
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 30
    }
    data_disk_details = []
  }
}