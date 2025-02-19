output "internet_gateway" {
  value       = module.vpc.internet_gateway
  description = "The ID of the internet gateway."
}

output "elastic_ips" {
  value       = module.vpc.elastic_ips
  description = "The ID of the elastic IPs."
}

output "nat_gateways" {
  value       = module.vpc.nat_gateways
  description = "The ID of the NAT gateways."
}

output "nat_gateways_public_ip" {
  value       = module.vpc.nat_gateways_public_ip
  description = "The ID of the NAT gateways."
}

output "route_tables" {
  value       = module.vpc.route_tables
  description = "The ID of the route tables."
}

output "subnets" {
  value       = module.vpc.subnets
  description = "The ID of the subnets."
}

output "vpc" {
  value       = module.vpc.vpc
  description = " The ID of the virtual private cloud."
}