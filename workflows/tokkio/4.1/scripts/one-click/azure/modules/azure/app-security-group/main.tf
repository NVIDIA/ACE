# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_security_group
resource "azurerm_application_security_group" "default" {
  for_each = var.application_security_groups

  name                = each.value
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule
resource "azurerm_network_security_rule" "default" {
  for_each = var.network_security_rules

  # Required
  access                      = title(each.value.access)
  direction                   = title(each.value.direction)
  name                        = each.value.rule_name
  network_security_group_name = each.value.network_security_group_name
  priority                    = each.value.priority
  protocol                    = title(each.value.protocol)
  resource_group_name         = var.resource_group_name

  # Optional
  destination_address_prefix                 = try(length(each.value.destination_address_prefixes), 0) + try(length(each.value.destination_application_security_groups), 0) == 0 ? "*" : try(length(each.value.destination_address_prefixes), 0) == 1 ? one(each.value.destination_address_prefixes) : null
  destination_address_prefixes               = try(length(each.value.destination_address_prefixes), 0) <= 1 ? null : each.value.destination_address_prefixes
  destination_application_security_group_ids = try(length(each.value.destination_application_security_groups), 0) == 0 ? null : [for g in each.value.destination_application_security_groups : try(azurerm_application_security_group.default[g].id, g)]
  destination_port_range                     = try(length(each.value.destination_port_ranges), 0) == 0 ? "*" : try(length(each.value.destination_port_ranges), 0) == 1 ? one(each.value.destination_port_ranges) : null
  destination_port_ranges                    = try(length(each.value.destination_port_ranges), 0) <= 1 ? null : each.value.destination_port_ranges
  source_address_prefix                      = try(length(each.value.source_address_prefixes), 0) + try(length(each.value.source_application_security_groups), 0) == 0 ? "*" : try(length(each.value.source_address_prefixes), 0) == 1 ? one(each.value.source_address_prefixes) : null
  source_address_prefixes                    = try(length(each.value.source_address_prefixes), 0) <= 1 ? null : each.value.source_address_prefixes
  source_application_security_group_ids      = try(length(each.value.source_application_security_groups), 0) == 0 ? null : [for g in each.value.source_application_security_groups : try(azurerm_application_security_group.default[g].id, g)]
  source_port_range                          = try(length(each.value.source_port_ranges), 0) == 0 ? "*" : try(length(each.value.source_port_ranges), 0) == 1 ? one(each.value.source_port_ranges) : null
  source_port_ranges                         = try(length(each.value.source_port_ranges), 0) <= 1 ? null : each.value.source_port_ranges

  depends_on = [azurerm_application_security_group.default]
}
