# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "default" {
  # Required
  address_space       = var.virtual_network.address_space
  location            = var.location
  name                = var.virtual_network.name
  resource_group_name = var.resource_group_name

  # Optional
  bgp_community           = var.virtual_network.bgp_community
  dns_servers             = var.virtual_network.dns_servers
  edge_zone               = var.virtual_network.edge_zone
  flow_timeout_in_minutes = var.virtual_network.flow_timeout_in_minutes
  tags                    = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.virtual_network.ddos_protection_plan != null ? [var.virtual_network.ddos_protection_plan] : []

    content {
      id     = ddos_protection_plan.value["ddos_protection_plan"]
      enable = ddos_protection_plan.value["enable"]
    }
  }

  # dynamic "encryption" {
  #   for_each = var.virtual_network.encryption != null ? [var.virtual_network.encryption] : []

  #   content {
  #     enforcement = encryption.value["enforcement"]
  #   }
  # }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network
data "azurerm_virtual_network" "default" {
  for_each = var.peers

  name                = each.key
  resource_group_name = each.value.resource_group_name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
resource "azurerm_virtual_network_peering" "outbound" {
  for_each = { for k, v in var.peers : k => v if contains(["Both", "Outbound"], title(v.direction)) }

  name                      = each.key
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.default.name
  remote_virtual_network_id = data.azurerm_virtual_network.default[each.key].id

  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  allow_virtual_network_access = each.value.allow_virtual_network_access
  use_remote_gateways          = each.value.use_remote_gateways
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
resource "azurerm_virtual_network_peering" "inbound" {
  for_each = { for k, v in var.peers : k => v if contains(["Both", "Inbound"], title(v.direction)) }

  name                      = each.key
  resource_group_name       = var.resource_group_name
  virtual_network_name      = each.key
  remote_virtual_network_id = azurerm_virtual_network.default.id

  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  allow_virtual_network_access = each.value.allow_virtual_network_access
  use_remote_gateways          = each.value.use_remote_gateways
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table
resource "azurerm_route_table" "default" {
  for_each = var.route_tables

  # Required
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  # Optional
  disable_bgp_route_propagation = each.value.disable_bgp_route_propagation
  tags                          = var.tags

  dynamic "route" {
    for_each = each.value.routes

    content {
      name = route.value.name

      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association.html
resource "azurerm_subnet_route_table_association" "default" {
  for_each = { for k, v in var.subnets : k => v if v.route_table_name != null }

  subnet_id      = azurerm_subnet.default[each.key].id
  route_table_id = azurerm_route_table.default[each.value.route_table_name].id
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "default" {
  for_each = var.subnets

  # Required
  name                 = each.key
  address_prefixes     = each.value.address_prefixes
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.default.name

  # Optional
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoints                             = each.value.service_endpoints
  service_endpoint_policy_ids                   = each.value.service_endpoint_policy_ids

  dynamic "delegation" {
    for_each = each.value.delegations

    content {
      name = delegation.key

      dynamic "service_delegation" {
        for_each = [delegation.value["service_delegation"]]

        content {
          name    = service_delegation.value["name"]
          actions = service_delegation.value["actions"]
        }
      }
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "default" {
  for_each = var.network_security_groups

  # Required
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  # Optional
  tags = var.tags
}

locals {
  # This will create a single list of all rules that will allow for a map to be create that the resource will iterate on.
  network_security_group_rules = flatten([for network_security_group_name, network_security_group in var.network_security_groups :
    flatten([for rule_name, rule in network_security_group.rules : merge(rule, {
      name                                       = rule_name,
      network_security_group_name                = network_security_group_name,
      destination_application_security_group_ids = rule.destination_application_security_group_ids
      source_application_security_group_ids      = rule.source_application_security_group_ids
    })])
  ])

  # Transform the list into a map for iteration.
  network_security_group_rules_map = {
    for rule in local.network_security_group_rules : "${rule.network_security_group_name}-${rule.name}" => rule
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule
resource "azurerm_network_security_rule" "default" {
  for_each = local.network_security_group_rules_map

  # Required
  access                      = title(each.value.access)
  direction                   = title(each.value.direction)
  name                        = each.value.name
  network_security_group_name = each.value.network_security_group_name
  priority                    = each.value.priority
  protocol                    = title(each.value.protocol)
  resource_group_name         = var.resource_group_name

  # Optional
  destination_address_prefix                 = each.value.destination_address_prefixes == null && each.value.destination_application_security_group_ids == null ? "*" : null
  destination_address_prefixes               = each.value.destination_address_prefixes
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
  destination_port_range                     = each.value.destination_port_ranges == null ? "*" : null
  destination_port_ranges                    = each.value.destination_port_ranges
  source_address_prefix                      = each.value.source_address_prefixes == null && each.value.source_application_security_group_ids == null ? "*" : null
  source_address_prefixes                    = each.value.source_address_prefixes
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  source_port_range                          = each.value.source_port_ranges == null ? "*" : null
  source_port_ranges                         = each.value.source_port_ranges

  depends_on = [azurerm_network_security_group.default]
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway
resource "azurerm_nat_gateway" "default" {
  for_each = var.nat_gateways

  # Required
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  # Optional
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  sku_name                = each.value.sku_name
  tags                    = var.tags
  zones                   = each.value.zones
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "default" {
  for_each = var.public_ips

  # Required
  name                = each.key
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = each.value.allocation_method

  # Optional
  ddos_protection_mode    = each.value.ddos_protection_mode
  ddos_protection_plan_id = each.value.ddos_protection_plan_id
  domain_name_label       = each.value.domain_name_label
  edge_zone               = each.value.edge_zone
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  ip_tags                 = each.value.ip_tags
  ip_version              = each.value.ip_version
  # Resolve public ip prefix id from created public ip prefixes. If that fails then use the input to allow the use of prefixes managed outside of the module.
  public_ip_prefix_id = try(azurerm_public_ip_prefix.default[each.value.public_ip_prefix_name].id, each.value.public_ip_prefix_name)
  reverse_fqdn        = each.value.reverse_fqdn
  sku                 = each.value.sku
  sku_tier            = each.value.sku_tier
  tags                = var.tags
  zones               = each.value.zones
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip_prefix
resource "azurerm_public_ip_prefix" "default" {
  for_each = var.public_ip_prefixes

  # Required
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = each.value.prefix_length

  # Optional
  ip_version = each.value.ip_version
  sku        = each.value.sku
  tags       = var.tags
  zones      = each.value.zones
}

locals {
  # Need a mapping of all subnets to network security groups.
  subnet_to_network_security_group_id_map = merge([
    for subnet_name, subnet in var.subnets : {
      for network_security_group_name in subnet.network_security_group_names : "${subnet_name}-${network_security_group_name}" => {
        subnet_id                 = azurerm_subnet.default[subnet_name].id
        network_security_group_id = azurerm_network_security_group.default[network_security_group_name].id
      }
    }]...
  )
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association
resource "azurerm_subnet_network_security_group_association" "default" {
  for_each = local.subnet_to_network_security_group_id_map

  subnet_id                 = each.value.subnet_id
  network_security_group_id = each.value.network_security_group_id
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association
resource "azurerm_nat_gateway_public_ip_association" "default" {
  for_each = { for k, v in var.nat_gateways : k => v if v.public_ip_name != null }

  nat_gateway_id       = azurerm_nat_gateway.default[each.key].id
  public_ip_address_id = azurerm_public_ip.default[each.value.public_ip_name].id
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_prefix_association
resource "azurerm_nat_gateway_public_ip_prefix_association" "default" {
  for_each = { for k, v in var.nat_gateways : k => v if v.public_ip_prefix_name != null }

  nat_gateway_id = azurerm_nat_gateway.default[each.key].id
  # Resolve public ip prefix id from created public ip prefixes. If that fails then use the input to allow the use of prefixes managed outside of the module.
  public_ip_prefix_id = try(azurerm_public_ip.default[each.value.public_ip_prefix_name].id, each.value.public_ip_prefix_name)
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association
resource "azurerm_subnet_nat_gateway_association" "default" {
  for_each = { for k, v in var.subnets : k => v if v.nat_gateway_name != null }

  subnet_id      = azurerm_subnet.default[each.key].id
  nat_gateway_id = azurerm_nat_gateway.default[each.value.nat_gateway_name].id
}
