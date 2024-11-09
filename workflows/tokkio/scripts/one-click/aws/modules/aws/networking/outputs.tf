output "internet_gateway" {
  value       = one(aws_internet_gateway.default[*].id)
  description = "The ID of the internet gateway."
}

output "elastic_ips" {
  value = {
    for k, v in aws_eip.default : k => v.id
  }
  description = "The ID of the elastic IPs."
}

output "nat_gateways" {
  value = {
    for k, v in aws_nat_gateway.default : k => v.id
  }
  description = "The ID of the NAT gateways."
}

output "nat_gateways_public_ip" {
  value = {
    for k, v in aws_nat_gateway.default : k => v.public_ip
  }
  description = "The public IP of the NAT gateways."
}


output "route_tables" {
  value = {
    for k, v in aws_route_table.default : k => v.id
  }
  description = "The ID of the route tables."
}

output "subnets" {
  value = {
    for k, v in aws_subnet.default : k => v.id
  }
  description = "The ID of the subnets."
}

output "vpc" {
  value       = aws_vpc.default.id
  description = " The ID of the virtual private cloud."
}
