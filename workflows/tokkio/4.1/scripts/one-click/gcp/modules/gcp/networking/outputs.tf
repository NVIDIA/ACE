output "ip_addresses" {
  value = {
    for k, v in google_compute_address.default : k => v
  }
  description = "The outputs of the created ip addresses."
}

output "nat_gateways" {
  value = {
    for k, v in google_compute_router_nat.default : k => v
  }
  description = "The outputs of the created nat gateways."
}

# output "network_security_address_groups" {
#   value = {
#     for k, v in google_network_security_address_group.default : k => v
#   }
#   description = "The outputs of the created network security address groups."
# }

output "routers" {
  value = {
    for k, v in google_compute_router.default : k => v
  }
  description = "The outputs of the created routers."
}

output "subnets" {
  value = {
    for k, v in google_compute_subnetwork.default : k => v
  }
  description = "The outputs of the created subnets."
}

output "virtual_private_clouds" {
  value = {
    for k, v in google_compute_network.default : k => v
  }
  description = "The outputs of the created virtual private clouds."
}
