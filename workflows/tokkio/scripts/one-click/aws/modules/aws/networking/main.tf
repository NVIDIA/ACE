# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "default" {
  cidr_block                           = var.virtual_private_cloud.cidr_block
  instance_tenancy                     = var.virtual_private_cloud.instance_tenancy
  ipv4_ipam_pool_id                    = var.virtual_private_cloud.ipv4_ipam_pool_id
  ipv4_netmask_length                  = var.virtual_private_cloud.ipv4_netmask_length
  ipv6_cidr_block                      = var.virtual_private_cloud.ipv6_cidr_block
  ipv6_ipam_pool_id                    = var.virtual_private_cloud.ipv6_ipam_pool_id
  ipv6_netmask_length                  = var.virtual_private_cloud.ipv6_netmask_length
  ipv6_cidr_block_network_border_group = var.virtual_private_cloud.ipv6_cidr_block_network_border_group
  assign_generated_ipv6_cidr_block     = var.virtual_private_cloud.assign_generated_ipv6_cidr_block
  enable_dns_hostnames                 = var.virtual_private_cloud.enable_dns_hostnames
  enable_dns_support                   = var.virtual_private_cloud.enable_dns_support
  enable_network_address_usage_metrics = var.virtual_private_cloud.enable_network_address_usage_metrics
  tags                                 = var.virtual_private_cloud.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
# Terraform Security Ignores
# Results #1 HIGH Subnet associates public IP address.
#   https://aquasecurity.github.io/tfsec/v1.28.4/checks/aws/ec2/no-public-ip-subnet/
# Public subnets are used for load balancers, NAT gateways, and other services that require public IP addresses.
#tfsec:ignore:aws-ec2-no-public-ip-subnet
resource "aws_subnet" "default" {
  for_each = var.subnets

  vpc_id = aws_vpc.default.id

  assign_ipv6_address_on_creation                = each.value.assign_ipv6_address_on_creation
  availability_zone                              = each.value.availability_zone
  availability_zone_id                           = each.value.availability_zone_id
  cidr_block                                     = each.value.cidr_block
  customer_owned_ipv4_pool                       = each.value.customer_owned_ipv4_pool
  enable_dns64                                   = each.value.enable_dns64
  #enable_lni_at_device_index                     = each.value.enable_lni_at_device_index
  enable_resource_name_dns_aaaa_record_on_launch = each.value.enable_resource_name_dns_aaaa_record_on_launch
  enable_resource_name_dns_a_record_on_launch    = each.value.enable_resource_name_dns_a_record_on_launch
  ipv6_cidr_block                                = each.value.ipv6_cidr_block
  ipv6_native                                    = each.value.ipv6_native
  map_customer_owned_ip_on_launch                = each.value.map_customer_owned_ip_on_launch
  map_public_ip_on_launch                        = each.value.map_public_ip_on_launch
  outpost_arn                                    = each.value.outpost_arn
  private_dns_hostname_type_on_launch            = each.value.private_dns_hostname_type_on_launch
  tags                                           = merge(each.value.tags, { Name = each.key })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl
resource "aws_network_acl" "default" {
  for_each = var.network_acls

  vpc_id = aws_vpc.default.id

  subnet_ids = each.value.subnet_ids
  tags       = merge(each.value.tags, { Name = each.key })

  dynamic "egress" {
    for_each = each.value.egress != null ? each.value.egress : []

    content {
      action          = egress.value["action"]
      from_port       = egress.value["from_port"]
      to_port         = egress.value["to_port"]
      protocol        = egress.value["protocol"]
      rule_no         = egress.value["rule_no"]
      cidr_block      = egress.value["cidr_block"]
      ipv6_cidr_block = egress.value["ipv6_cidr_block"]
      icmp_code       = egress.value["icmp_code"]
      icmp_type       = egress.value["icmp_type"]
    }
  }

  dynamic "ingress" {
    for_each = each.value.ingress != null ? each.value.ingress : []

    content {
      action          = ingress.value["action"]
      from_port       = ingress.value["from_port"]
      to_port         = ingress.value["to_port"]
      protocol        = ingress.value["protocol"]
      rule_no         = ingress.value["rule_no"]
      cidr_block      = ingress.value["cidr_block"]
      ipv6_cidr_block = ingress.value["ipv6_cidr_block"]
      icmp_code       = ingress.value["icmp_code"]
      icmp_type       = ingress.value["icmp_type"]
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "default" {
  count = var.internet_gateway.enabled ? 1 : 0

  vpc_id = aws_vpc.default.id
  tags   = var.internet_gateway.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "default" {
  count = var.internet_gateway.enabled ? 1 : 0

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default[0].id
  route_table_id         = aws_vpc.default.default_route_table_id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "default" {
  for_each = var.elastic_ips

  address                   = each.value.address
  associate_with_private_ip = each.value.associate_with_private_ip
  customer_owned_ipv4_pool  = each.value.customer_owned_ipv4_pool
  #domain                    = each.value.domain
  instance                  = each.value.instance
  network_border_group      = each.value.network_border_group
  network_interface         = each.value.network_interface
  public_ipv4_pool          = each.value.public_ipv4_pool
  tags                      = merge(each.value.tags, { Name = each.key })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
resource "aws_nat_gateway" "default" {
  for_each = var.nat_gateways

  subnet_id                          = each.value.subnet_id
  allocation_id                      = each.value.allocation_id
  connectivity_type                  = each.value.connectivity_type
  private_ip                         = each.value.private_ip
  #secondary_allocation_ids           = each.value.secondary_allocation_ids
  #secondary_private_ip_address_count = each.value.secondary_private_ip_address_count
  #secondary_private_ip_addresses     = each.value.secondary_private_ip_addresses
  tags                               = merge(each.value.tags, { Name = each.key })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "default" {
  for_each = var.route_tables

  vpc_id = aws_vpc.default.id

  propagating_vgws = each.value.propagating_vgws
  tags             = merge(each.value.tags, { Name = each.key })

  dynamic "route" {
    for_each = each.value.routes != null ? each.value.routes : []

    content {
      cidr_block                 = route.value["cidr_block"]
      carrier_gateway_id         = route.value["carrier_gateway_id"]
      core_network_arn           = route.value["core_network_arn"]
      destination_prefix_list_id = route.value["destination_prefix_list_id"]
      egress_only_gateway_id     = route.value["egress_only_gateway_id"]
      gateway_id                 = route.value["gateway_id"]
      ipv6_cidr_block            = route.value["ipv6_cidr_block"]
      local_gateway_id           = route.value["local_gateway_id"]
      nat_gateway_id             = route.value["nat_gateway_id"]
      network_interface_id       = route.value["network_interface_id"]
      transit_gateway_id         = route.value["transit_gateway_id"]
      vpc_endpoint_id            = route.value["vpc_endpoint_id"]
      vpc_peering_connection_id  = route.value["vpc_peering_connection_id"]
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "default" {
  for_each = var.route_tables

  route_table_id = aws_route_table.default[each.key].id
  subnet_id      = each.value.subnet_id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection
resource "aws_vpc_peering_connection" "default" {
  for_each = var.peering_connections

  peer_vpc_id = each.value.peer_vpc_id
  vpc_id      = aws_vpc.default.id

  auto_accept   = each.value.auto_accept
  peer_owner_id = each.value.peer_owner_id
  peer_region   = each.value.peer_region
  tags          = merge(each.value.tags, { Name = each.key })

  dynamic "accepter" {
    for_each = each.value.accepter != null ? [each.value.accepter] : []

    content {
      allow_remote_vpc_dns_resolution = accepter.value["allow_remote_vpc_dns_resolution"]
    }
  }

  dynamic "requester" {
    for_each = each.value.requester != null ? [each.value.requester] : []

    content {
      allow_remote_vpc_dns_resolution = requester.value["allow_remote_vpc_dns_resolution"]
    }
  }
}
