output "virtual_network" {
  value = module.virtual_network.virtual_network
}

output "route_table" {
  value = module.virtual_network.route_table
}

output "subnet" {
  value = module.virtual_network.subnet
}

output "network_security_group" {
  value = module.virtual_network.network_security_group
}

output "nat_gateway" {
  value = module.virtual_network.nat_gateway
}

output "public_ip" {
  value = module.virtual_network.public_ip
}

output "public_ip_prefix" {
  value = module.virtual_network.public_ip_prefix
}
