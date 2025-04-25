output "virtual_network" {
  value = azurerm_virtual_network.default.id
}

output "virtual_network_peering" {
  value = {
    "outbound" = {
      for k, v in azurerm_virtual_network_peering.outbound : k => v.id
    }
    "inbound" = {
      for k, v in azurerm_virtual_network_peering.inbound : k => v.id
    }
  }
}

output "route_table" {
  value = {
    for k, v in azurerm_route_table.default : k => v.id
  }
}

output "subnet" {
  value = {
    for k, v in azurerm_subnet.default : k => v.id
  }
}

output "network_security_group" {
  value = {
    for k, v in azurerm_network_security_group.default : k => v.id
  }
}

output "nat_gateway" {
  value = {
    for k, v in azurerm_nat_gateway.default : k => v.id
  }
}

output "public_ip" {
  value = {
    for k, v in azurerm_public_ip.default : k => {
      id = v.id
      ip = v.ip_address
    }
  }
}

output "public_ip_prefix" {
  value = {
    for k, v in azurerm_public_ip_prefix.default : k => v.id
  }
}
