data "azurerm_client_config" "current" {}

locals {
  name     = var.name
  location = var.location

  bastion_sg_name        = format("%s-bastion", local.name)
  bastion_inventory_name = "bastion"
  master_inventory_name  = "master"
  ssh_user               = "ubuntu"
  ansible_ssh_extra_args = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

  access_ips = flatten([for cidr in var.user_access_cidrs : [for host_number in range(pow(2, 32 - split("/", cidr)[1])) : cidrhost(cidr, host_number)]])
  access_cidrs = concat(
    [for controller_ip in [var.controller_ip] : format("%s/32", controller_ip) if !contains(local.access_ips, controller_ip)],
    var.user_access_cidrs
  )
  dev_access_ips = flatten([for cidr in var.dev_access_cidrs : [for host_number in range(pow(2, 32 - split("/", cidr)[1])) : cidrhost(cidr, host_number)]])
  dev_access_cidrs = concat(
    [for controller_ip in [var.controller_ip] : format("%s/32", controller_ip) if !contains(local.dev_access_ips, controller_ip)],
    var.dev_access_cidrs
  )
  image_offer       = "0001-com-ubuntu-server-jammy"
  image_publisher   = "canonical"
  image_sku         = "22_04-lts-gen2"
  image_version     = "latest"
  private_vm_subnet = "private-vm"
  public_vm_subnet  = "public-vm"
  app_gw_subnet     = "public-app-gw"
  private_cluster_node_port_ranges = {
    for cluster in keys(var.clusters) : cluster => [
      for port in values(var.clusters[cluster].ports) : format("%s-%s", port.port, port.port)
    ] if var.clusters[cluster].private_instance
  }
  public_cluster_node_port_ranges = {
    for cluster in keys(var.clusters) : cluster => [
      for port in values(var.clusters[cluster].ports) : format("%s-%s", port.port, port.port)
    ] if !var.clusters[cluster].private_instance
  }
  private_cluster_exists   = anytrue([for cluster in values(var.clusters) : cluster.private_instance])
  public_cluster_exists    = anytrue([for cluster in values(var.clusters) : !cluster.private_instance])
  private_cluster_sg_names = [for cluster in sort(keys(var.clusters)) : format("%s-%s", local.name, cluster) if var.clusters[cluster].private_instance]
  public_cluster_sg_names  = [for cluster in sort(keys(var.clusters)) : format("%s-%s", local.name, cluster) if !var.clusters[cluster].private_instance]
  private_nsg_name         = one([for nsg in keys(module.networking.network_security_group) : nsg if nsg == "private"])
  public_nsg_name          = one([for nsg in keys(module.networking.network_security_group) : nsg if nsg == "public"])
  nat_gateway_ips          = [for nat_gateway_name in sort(keys(module.networking.nat_gateway)) : module.networking.public_ip[nat_gateway_name]["ip"]]
  private_vm_subnet_id     = one([for subnet in sort(keys(module.networking.subnet)) : module.networking.subnet[subnet] if subnet == local.private_vm_subnet])
  public_vm_subnet_id      = one([for subnet in sort(keys(module.networking.subnet)) : module.networking.subnet[subnet] if subnet == local.public_vm_subnet])
  app_gw_subnet_id         = one([for subnet in sort(keys(module.networking.subnet)) : module.networking.subnet[subnet] if subnet == local.app_gw_subnet])
  private_nsg_rules = []

  public_nsg_rules_coturn = [
    {
      name                                    = "coturn-allowport-tcp"
      rule_name                               = "AllowCoturnInboundTCP"
      access                                  = "Allow"
      direction                               = "Inbound"
      network_security_group_name             = local.public_nsg_name
      priority                                = 3100
      protocol                                = "Tcp"
      description                             = "coturn tcp port access from CIDRs"
      destination_address_prefixes            = ["*"]
      destination_application_security_groups = []
      destination_port_ranges                 = ["3478"]
      source_address_prefixes                 = concat(local.access_cidrs, [module.networking.public_ip.nat-gateway["ip"]])
      source_application_security_groups      = []
      include_if                              = local.public_cluster_exists
    },
    {
      name                                    = "coturn-allowport-udp"
      rule_name                               = "AllowCoturnInboundUDP"
      access                                  = "Allow"
      direction                               = "Inbound"
      network_security_group_name             = local.public_nsg_name
      priority                                = 3600
      protocol                                = "Udp"
      description                             = "coturn udp port access from CIDRs"
      destination_address_prefixes            = ["*"]
      destination_application_security_groups = []
      destination_port_ranges                 = ["3478"]
      source_address_prefixes                 = concat(local.access_cidrs, [module.networking.public_ip.nat-gateway["ip"]])
      source_application_security_groups      = []
      include_if                              = local.public_cluster_exists
    },
    {
      name                                    = "coturn-allowport-udprange"
      rule_name                               = "AllowCoturnInboundUDPrange"
      access                                  = "Allow"
      direction                               = "Inbound"
      network_security_group_name             = local.public_nsg_name
      priority                                = 4000
      protocol                                = "Udp"
      description                             = "coturn udp port access from CIDRs"
      destination_address_prefixes            = ["*"]
      destination_application_security_groups = []
      destination_port_ranges                 = ["49152-65535"]
      source_address_prefixes                 = concat(local.access_cidrs, [module.networking.public_ip.nat-gateway["ip"]])
      source_application_security_groups      = []
      include_if                              = local.public_cluster_exists
    }
  ]

  public_nsg_rules_rp = [
    {
      name                         = "rp-allowport-udprange"
      rule_name                    = "AllowRPInboundUDPrange"
      priority                     = 3700
      direction                    = "Inbound"
      network_security_group_name  = local.public_nsg_name
      access                       = "Allow"
      protocol                     = "Udp"
      description                  = "RP udp port range access from CIDRs"
      destination_address_prefixes = ["*"]
      destination_application_security_groups = []
      destination_port_ranges      = ["10000-20000"]
      source_address_prefixes      = concat(local.access_cidrs, [module.networking.public_ip.nat-gateway["ip"]])
      source_application_security_groups = []
      include_if                   = local.public_cluster_exists
    }
  ]

  public_nsg_rules_twilio = []

  public_nsg_rules_common = concat([
    {
      name                                    = "pub-bastion-AllowSSHInbound"
      rule_name                               = "AllowSSHInboundForBastion"
      access                                  = "Allow"
      direction                               = "Inbound"
      network_security_group_name             = local.public_nsg_name
      priority                                = 1600
      protocol                                = "Tcp"
      description                             = "SSH access from access CIDRs"
      destination_address_prefixes            = ["*"]
      destination_application_security_groups = []
      destination_port_ranges                 = ["22"]
      source_address_prefixes                 = local.dev_access_cidrs
      source_application_security_groups      = []
      include_if                              = local.private_cluster_exists
    },
    {
      name                                    = "pub-app-gw-AllowGatewayManagerInbound"
      rule_name                               = "AllowGatewayManagerInboundForAppGateway"
      access                                  = "Allow"
      direction                               = "Inbound"
      network_security_group_name             = local.public_nsg_name
      priority                                = 2100
      protocol                                = "*"
      description                             = "SSH access from access CIDRs"
      destination_address_prefixes            = ["*"]
      destination_application_security_groups = []
      destination_port_ranges                 = ["65200-65535"]
      source_address_prefixes                 = ["GatewayManager"]
      source_application_security_groups      = []
      include_if                              = local.private_cluster_exists
    },
    {
      name                                    = "pub-app-gw-Allowappapi"
      rule_name                               = "AllowPublicAccess"
      access                                  = "Allow"
      direction                               = "Inbound"
      network_security_group_name             = local.public_nsg_name
      priority                                = 2600
      protocol                                = "Tcp"
      description                             = "APP API access from access CIDRs"
      destination_address_prefixes            = ["*"]
      destination_application_security_groups = []
      destination_port_ranges                 = ["443"]
      source_address_prefixes                 = local.access_cidrs
      source_application_security_groups      = []
      include_if                              = local.private_cluster_exists
    },
    {
      name                                    = "pub-cluster-AllowSSHInbound"
      rule_name                               = "AllowSSHInboundForCluster"
      access                                  = "Allow"
      direction                               = "Inbound"
      network_security_group_name             = local.public_nsg_name
      priority                                = 1100
      protocol                                = "Tcp"
      description                             = "SSH access from access CIDRs"
      destination_address_prefixes            = ["*"]
      destination_application_security_groups = []
      destination_port_ranges                 = ["22"]
      source_address_prefixes                 = local.dev_access_cidrs
      source_application_security_groups      = []
      include_if                              = local.public_cluster_exists
    }
    # {
    #   name                                    = "pub-cluster-AllowNodePortInbound"
    #   rule_name                               = "AllowNodePortInbound"
    #   access                                  = "Allow"
    #   direction                               = "Inbound"
    #   network_security_group_name             = local.public_nsg_name
    #   priority                                = 1101
    #   protocol                                = "Tcp"
    #   description                             = "Node Port access from access CIDRs"
    #   destination_address_prefixes            = ["*"]
    #   destination_application_security_groups = []
    #   destination_port_ranges                 = distinct(compact(flatten(values(local.public_cluster_node_port_ranges))))
    #   source_address_prefixes                 = local.access_cidrs
    #   source_application_security_groups      = []
    #   include_if                              = local.public_cluster_exists
    # },
    # {
    #   name                                    = "pub-app-gateway-AllowAppPortInbound"
    #   rule_name                               = "AllowAppPortInbound"
    #   access                                  = "Allow"
    #   direction                               = "Inbound"
    #   network_security_group_name             = local.public_nsg_name
    #   priority                                = 1102
    #   protocol                                = "Tcp"
    #   description                             = "App Gateway Port access from access CIDRs"
    #   destination_address_prefixes            = ["*"]
    #   destination_application_security_groups = []
    #   destination_port_ranges                 = distinct(compact(flatten(values(local.private_cluster_node_port_ranges))))
    #   source_address_prefixes                 = local.access_cidrs
    #   source_application_security_groups      = []
    #   include_if                              = local.private_cluster_exists
    # }
    ]
  )
  public_nsg_rules = ( var.turn_server_provider == "coturn" ? concat(local.public_nsg_rules_coturn,local.public_nsg_rules_common) :
                       var.turn_server_provider == "rp" ? concat(local.public_nsg_rules_rp,local.public_nsg_rules_common) :
                       var.turn_server_provider == "twilio" ? concat(local.public_nsg_rules_twilio,local.public_nsg_rules_common) :
                       local.public_nsg_rules_common )
  network_security_rules = { for rule in concat(local.private_nsg_rules, local.public_nsg_rules) : rule.name => rule if rule.include_if }
  bastion = {
    admin_username   = local.ssh_user
    attach_public_ip = true
    image_offer      = local.image_offer
    image_publisher  = local.image_publisher
    image_sku        = local.image_sku
    image_version    = local.image_version
  }
  cluster = {
    admin_username  = local.ssh_user
    image_offer     = local.image_offer
    image_publisher = local.image_publisher
    image_sku       = local.image_sku
    image_version   = local.image_version
  }

#tokkio 
  tenant_id         = data.azurerm_client_config.current.tenant_id
  object_id         = data.azurerm_client_config.current.object_id
  certificate_vault_access_policies = [
    {
      identifier     = "creator"
      tenant_id      = local.tenant_id
      application_id = ""
      object_id      = local.object_id
      certificate_permissions = [
        "Get",
        "List",
        "Update",
        "Create",
        "Import",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
        "ManageContacts",
        "ManageIssuers",
        "GetIssuers",
        "ListIssuers",
        "SetIssuers",
        "DeleteIssuers",
        "Purge"
      ]
      key_permissions = [
        "Get",
        "List",
        "Update",
        "Create",
        "Import",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
        "GetRotationPolicy",
        "SetRotationPolicy",
        "Rotate"
      ]
      secret_permissions = [
        "Get",
        "List",
        "Set",
        "Delete",
        "Recover",
        "Backup",
        "Restore"
      ]
      storage_permissions = []
    },
    {
      identifier     = "cert-reader"
      tenant_id      = azurerm_user_assigned_identity.certificate_reader.tenant_id
      application_id = ""
      object_id      = azurerm_user_assigned_identity.certificate_reader.principal_id
      certificate_permissions = [
        "Get",
        "List",
        "GetIssuers",
        "ListIssuers"
      ]
      key_permissions = []
      secret_permissions = [
        "Get",
        "List"
      ]
      storage_permissions = []
    }
  ]
  wildcard_certificate_b64_content = var.dns_and_certs_configs.wildcard_cert
  base_domain        = var.dns_and_certs_configs.dns_zone
  ace_configurator_sub_domain = coalesce(var.ace_configurator_sub_domain, format("%s-ace-configurator", var.name))
  grafana_sub_domain = coalesce(var.grafana_sub_domain, format("%s-grafana", var.name))
  api_sub_domain     = coalesce(var.api_sub_domain, format("%s-api", var.name))
  ui_sub_domain      = coalesce(var.ui_sub_domain, format("%s-ui", var.name))
  ace_configurator_domain = format("%s.%s", local.ace_configurator_sub_domain, local.base_domain)
  grafana_domain     = format("%s.%s", local.grafana_sub_domain, local.base_domain)
  api_domain         = format("%s.%s", local.api_sub_domain, local.base_domain)
  api_app_gw_frontend_port = 443
  ops_domain         = [local.grafana_domain, local.ace_configurator_domain]
  api_app_gw_ssl_certificate_name           = format("%s-api-cert", var.name)
  ui_storage_account_name = replace(format("%s-ui",local.name), "/\\W/", "")
  ui_website_index_document     = "index.html"
  ui_website_error_404_document = "index.html"
  ui_cdn_profile_name           = format("%s-cdn", local.name)
  ui_cdn_endpoint_name          = local.ui_sub_domain
  ui_domain         = var.include_ui_custom_domain ? one(module.ui_custom_domain.*.custom_domain_fqdn) : module.ui_cdn.endpoint_fqdn
  ui_endpoint       = format("https://%s", local.ui_domain)
  identity = {
    identity_ids = [
      azurerm_user_assigned_identity.ui_uploader.id
    ]
    type = "UserAssigned"
  }
  #ui_storage_account_name          = module.ui_storage_account.name
  ui_storage_access_client_id      = azurerm_user_assigned_identity.ui_uploader.client_id

  data_disk_details = [ for cluster_name, cluster in var.clusters : {
    name = "data-disk-0"
    storage_account_type = "Premium_LRS"
    disk_size_gb = cluster.master["data_disk_size_gb"]
    lun = 0
    caching = "ReadOnly"
  } if var.clusters[cluster_name].private_instance ]
  turn_server_provider = var.turn_server_provider
  use_reverse_proxy = local.turn_server_provider == "rp" ? true : false
  use_twilio_stun_turn = local.turn_server_provider == "twilio" ? true : false

  hostname_map = {
    "ops"              = local.grafana_domain,
    "ace_configurator" = local.ace_configurator_domain,
    "default"          = local.api_domain
  }

}