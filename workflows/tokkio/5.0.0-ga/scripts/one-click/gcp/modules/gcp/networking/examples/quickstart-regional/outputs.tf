output "ip_addresses" {
  value       = module.vpc.ip_addresses
  description = "The outputs of the created ip addresses."
}

output "nat_gateways" {
  value       = module.vpc.nat_gateways
  description = "The outputs of the created nat gateways."
}

# output "network_security_address_groups" {
#   value       = module.vpc.network_security_address_groups
#   description = "The outputs of the created network security address groups."
# }

output "routers" {
  value       = module.vpc.routers
  description = "The outputs of the created routers."
}

output "subnets" {
  value       = module.vpc.subnets
  description = "The outputs of the created subnets."
}

output "virtual_private_cloud" {
  value       = module.vpc.virtual_private_clouds["default"]
  description = "The output of the created virtual private cloud."
}

output "nat_gateways_ip" {
  value       = module.vpc.ip_addresses["nat"].address
  description = "The outputs of the created nat gateways."
}