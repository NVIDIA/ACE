
resource "azurerm_virtual_network" "virtual_network" {
  name                = format("%s-vnet", var.name)
  location            = var.region
  resource_group_name = var.resource_group_name
  address_space       = [var.virtual_network_address_space]
  tags                = var.additional_tags
}

resource "azurerm_subnet" "subnet" {
  for_each             = { for subnet in var.subnet_details : subnet.identifier => subnet }
  name                 = format("%s-%s", var.name, each.key)
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = [each.value["address_prefix"]]
  service_endpoints    = each.value["service_endpoints"]
}

resource "azurerm_public_ip" "nat_public_ip" {
  name                = format("%s-nat-gw", var.name)
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.additional_tags
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                = format("%s-nat-gw", var.name)
  location            = var.region
  resource_group_name = var.resource_group_name
  tags                = var.additional_tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_public_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_nat_gateway_association" {
  for_each = {
    for subnet in var.subnet_details : subnet.identifier => subnet
    if subnet.associate_nat_gateway
  }
  subnet_id      = azurerm_subnet.subnet[each.key].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

resource "azurerm_network_security_group" "network_security_group" {
  for_each            = { for group in var.network_security_groups : group.identifier => group }
  name                = format("%s-%s", var.name, each.key)
  location            = var.region
  resource_group_name = var.resource_group_name
  tags                = var.additional_tags
}

resource "azurerm_network_security_rule" "network_security_rule" {
  for_each                     = { for rule in var.network_security_rules : format("%s-%s", rule.nsg_identifier, rule.name) => rule }
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.network_security_group[each.value["nsg_identifier"]].name
  name                         = each.value["name"]
  priority                     = each.value["priority"]
  direction                    = each.value["direction"]
  access                       = each.value["access"]
  protocol                     = each.value["protocol"]
  source_port_range            = each.value["source_port_range"]
  source_port_ranges           = each.value["source_port_ranges"]
  destination_port_range       = each.value["destination_port_range"]
  destination_port_ranges      = each.value["destination_port_ranges"]
  source_address_prefix        = each.value["include_nat_as_source"] == false ? each.value["source_address_prefix"] : null
  source_address_prefixes      = each.value["include_nat_as_source"] == true ? concat((each.value["source_address_prefix"] == null ? each.value["source_address_prefixes"] : [each.value["source_address_prefix"]]), [format("%s/32", azurerm_public_ip.nat_public_ip.ip_address)]) : each.value["source_address_prefixes"]
  destination_address_prefix   = each.value["destination_address_prefix"]
  destination_address_prefixes = each.value["destination_address_prefixes"]
}

resource "azurerm_subnet_network_security_group_association" "subnet_network_security_group_association" {
  for_each                  = { for subnet in var.subnet_details : subnet.identifier => subnet }
  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.network_security_group[each.value["nsg_identifier"]].id
}