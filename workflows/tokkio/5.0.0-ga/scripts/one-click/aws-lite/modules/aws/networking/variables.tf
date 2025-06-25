variable "elastic_ips" {
  type = map(object({
    address                   = optional(string)
    associate_with_private_ip = optional(string)
    customer_owned_ipv4_pool  = optional(string)
    domain                    = optional(string)
    instance                  = optional(string)
    network_border_group      = optional(string)
    network_interface         = optional(string)
    public_ipv4_pool          = optional(string)
    tags                      = optional(map(string))
  }))
  description = <<EOF
    address                   = (Optional) IP address from an EC2 BYOIP pool. This option is only available for VPC EIPs.
    associate_with_private_ip = (Optional) User-specified primary or secondary private IP address to associate with the Elastic IP address. If no private IP address is specified, the Elastic IP address is associated with the primary private IP address.
    customer_owned_ipv4_pool  = (Optional) ID of a customer-owned address pool.
    domain                    = Indicates if this EIP is for use in VPC (vpc).
    instance                  = (Optional) EC2 instance ID.
    network_border_group      = (Optional) Location from which the IP address is advertised. Use this parameter to limit the address to this location.
    network_interface         = (Optional) Network interface ID to associate with.
    public_ipv4_pool          = (Optional) EC2 IPv4 address pool identifier or amazon. This option is only available for VPC EIPs.
    tags                      = (Optional) Map of tags to assign to the resource. Tags can only be applied to EIPs in a VPC. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  EOF
  default     = {}
}

variable "internet_gateway" {
  type = object({
    enabled = optional(bool, false)
    tags    = optional(map(string))
  })
  description = <<EOF
    enabled = (Optional) A boolean flag to enable/disable the internet gateway.
    tags    = (Optional) A map of tags to assign to the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  EOF
  default     = {}
}

variable "network_acls" {
  type = map(object({
    subnet_ids = optional(list(string))
    egress = optional(list(object({
      action          = string
      from_port       = number
      to_port         = number
      protocol        = string
      rule_no         = number
      cidr_block      = optional(string)
      ipv6_cidr_block = optional(string)
      icmp_code       = optional(number)
      icmp_type       = optional(number)
    })))
    ingress = optional(list(object({
      action          = string
      from_port       = number
      to_port         = number
      protocol        = string
      rule_no         = number
      cidr_block      = optional(string)
      ipv6_cidr_block = optional(string)
      icmp_code       = optional(number)
      icmp_type       = optional(number)
    })))
    tags = optional(map(string))
  }))
  description = <<EOF
    subnet_ids        = (Optional) A list of Subnet IDs to apply the ACL to.
    egress            = (Optional) Specifies an egress rule. Parameters defined below. This argument is processed in attribute-as-blocks mode.
      action          = (Required) The action to take.
      from_port       = (Required) The from port to match.
      to_port         = (Required) The to port to match.
      protocol        = (Required) The protocol to match. If using the -1 'all' protocol, you must specify a from and to port of 0.
      rule_no         = (Required) The rule number. Used for ordering.
      cidr_block      = (Optional) The CIDR block to match. This must be a valid network mask.
      ipv6_cidr_block = (Optional) The IPv6 CIDR block.
      icmp_code       = (Optional) The ICMP type code to be used. Default 0.
      icmp_type       = (Optional) The ICMP type to be used. Default 0.
    ingress           = (Optional) Specifies an ingress rule. Parameters defined below. This argument is processed in attribute-as-blocks mode.
      action          = (Required) The action to take.
      from_port       = (Required) The from port to match.
      to_port         = (Required) The to port to match.
      protocol        = (Required) The protocol to match. If using the -1 'all' protocol, you must specify a from and to port of 0.
      rule_no         = (Required) The rule number. Used for ordering.
      cidr_block      = (Optional) The CIDR block to match. This must be a valid network mask.
      ipv6_cidr_block = (Optional) The IPv6 CIDR block.
      icmp_code       = (Optional) The ICMP type code to be used. Default 0.
      icmp_type       = (Optional) The ICMP type to be used. Default 0.
    tags              = (Optional) A map of tags to assign to the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  EOF
  default     = {}
}

variable "nat_gateways" {
  type = map(object({
    subnet_id                          = string
    allocation_id                      = optional(string)
    connectivity_type                  = optional(string)
    private_ip                         = optional(string)
    secondary_allocation_ids           = optional(list(string))
    secondary_private_ip_address_count = optional(number)
    secondary_private_ip_addresses     = optional(list(string))
    tags                               = optional(map(string))
  }))
  description = <<EOF
    subnet_id                          = (Required) The Subnet ID of the subnet in which to place the NAT Gateway.
    allocation_id                      = (Optional) The Allocation ID of the Elastic IP address for the NAT Gateway. Required for connectivity_type of public.
    connectivity_type                  = (Optional) Connectivity type for the NAT Gateway. Valid values are private and public. Defaults to public.
    private_ip                         = (Optional) The private IPv4 address to assign to the NAT Gateway. If you don't provide an address, a private IPv4 address will be automatically assigned.
    secondary_allocation_ids           = (Optional) A list of secondary allocation EIP IDs for this NAT Gateway.
    secondary_private_ip_address_count = (Optional) [Private NAT Gateway only] The number of secondary private IPv4 addresses you want to assign to the NAT Gateway.
    secondary_private_ip_addresses     = (Optional) A list of secondary private IPv4 addresses to assign to the NAT Gateway.
    tags                               = (Optional) A map of tags to assign to the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  EOF
  default     = {}
}

variable "peering_connections" {
  type = map(object({
    peer_vpc_id = string
    accepter = optional(object({
      allow_remote_vpc_dns_resolution = bool
    }))
    auto_accept   = optional(bool)
    peer_owner_id = optional(string)
    peer_region   = optional(string)
    requester = optional(object({
      allow_remote_vpc_dns_resolution = bool
    }))
    tags = optional(map(string))
  }))
  description = <<EOF
    peer_vpc_id                       = (Required) The ID of the target VPC with which you are creating the VPC Peering Connection.
    accepter                          = (Optional) - An optional configuration block that allows for VPC Peering Connection options to be set for the VPC that accepts the peering connection (a maximum of one).
      allow_remote_vpc_dns_resolution = (Optional) Allow a local VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the peer VPC.
    auto_accept                       = (Optional) Accept the peering (both VPCs need to be in the same AWS account and region).
    peer_owner_id                     = (Optional) The AWS account ID of the target peer VPC. Defaults to the account ID the AWS provider is currently connected to, so must be managed if connecting cross-account.
    peer_region                       = (Optional) The region of the accepter VPC of the VPC Peering Connection. auto_accept must be false, and use the aws_vpc_peering_connection_accepter to manage the accepter side.
    requester                         = (Optional) - A optional configuration block that allows for VPC Peering Connection options to be set for the VPC that requests the peering connection (a maximum of one).
      allow_remote_vpc_dns_resolution = (Optional) Allow a local VPC to resolve public DNS hostnames to private IP addresses when queried from instances in the peer VPC.
    tags                              = (Optional) A map of tags to assign to the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  EOF
  default     = {}
}

variable "route_tables" {
  type = map(object({
    routes = optional(list(object({
      cidr_block                 = string
      carrier_gateway_id         = optional(string)
      core_network_arn           = optional(string)
      destination_prefix_list_id = optional(string)
      egress_only_gateway_id     = optional(string)
      gateway_id                 = optional(string)
      ipv6_cidr_block            = optional(string)
      local_gateway_id           = optional(string)
      nat_gateway_id             = optional(string)
      network_interface_id       = optional(string)
      transit_gateway_id         = optional(string)
      vpc_endpoint_id            = optional(string)
      vpc_peering_connection_id  = optional(string)
    })))
    propagating_vgws = optional(list(string))
    subnet_id        = optional(string)
    tags             = optional(map(string))
  }))
  description = <<EOF
    routes                       = (Optional) A list of route objects. Their keys are documented below. This argument is processed in attribute-as-blocks mode. This means that omitting this argument is interpreted as ignoring any existing routes. To remove all managed routes an empty list should be specified.
      cidr_block                 = (Required) The CIDR block of the route.
      carrier_gateway_id         = (Optional) Identifier of a carrier gateway. This attribute can only be used when the VPC contains a subnet which is associated with a Wavelength Zone.
      core_network_arn           = (Optional) The Amazon Resource Name (ARN) of a core network.
      destination_prefix_list_id = (Optional) The ID of a managed prefix list destination of the route.
      egress_only_gateway_id     = (Optional) Identifier of a VPC Egress Only Internet Gateway.
      gateway_id                 = (Optional) Identifier of a VPC internet gateway, virtual private gateway, or local. local routes cannot be created but can be adopted or imported.
      ipv6_cidr_block            = (Optional) The Ipv6 CIDR block of the route.
      local_gateway_id           = (Optional) Identifier of a Outpost local gateway.
      nat_gateway_id             = (Optional) Identifier of a VPC NAT gateway.
      network_interface_id       = (Optional) Identifier of an EC2 network interface.
      transit_gateway_id         = (Optional) Identifier of an EC2 Transit Gateway.
      vpc_endpoint_id            = (Optional) Identifier of a VPC Endpoint.
      vpc_peering_connection_id  = (Optional) Identifier of a VPC peering connection.
    propagating_vgws             = (Optional) A list of virtual gateways for propagation.
    subnet_id                    = (Optional) The ID of the subnet to associate with the route table.
    tags                         = (Optional) A map of tags to assign to the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  EOF
  default     = {}
}

variable "subnets" {
  type = map(object({
    assign_ipv6_address_on_creation                = optional(bool)
    availability_zone                              = optional(string)
    availability_zone_id                           = optional(string)
    cidr_block                                     = optional(string)
    customer_owned_ipv4_pool                       = optional(string)
    enable_dns64                                   = optional(bool)
    enable_lni_at_device_index                     = optional(number)
    enable_resource_name_dns_aaaa_record_on_launch = optional(bool)
    enable_resource_name_dns_a_record_on_launch    = optional(bool)
    ipv6_cidr_block                                = optional(string)
    ipv6_native                                    = optional(bool)
    map_customer_owned_ip_on_launch                = optional(bool)
    map_public_ip_on_launch                        = optional(bool)
    outpost_arn                                    = optional(string)
    private_dns_hostname_type_on_launch            = optional(string)
    tags                                           = optional(map(string))
  }))
  description = <<EOF
    assign_ipv6_address_on_creation                = (Optional) Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address. Default is false
    availability_zone                              = (Optional) AZ for the subnet.
    availability_zone_id                           = (Optional) AZ ID of the subnet. This argument is not supported in all regions or partitions. If necessary, use availability_zone instead.
    cidr_block                                     = (Optional) The IPv4 CIDR block for the subnet.
    customer_owned_ipv4_pool                       = (Optional) The customer owned IPv4 address pool. Typically used with the map_customer_owned_ip_on_launch argument. The outpost_arn argument must be specified when configured.
    enable_dns64                                   = (Optional) Indicates whether DNS queries made to the Amazon-provided DNS Resolver in this subnet should return synthetic IPv6 addresses for IPv4-only destinations. Default: false.
    enable_lni_at_device_index                     = (Optional) Indicates the device position for local network interfaces in this subnet. For example, 1 indicates local network interfaces in this subnet are the secondary network interface (eth1). A local network interface cannot be the primary network interface (eth0).
    enable_resource_name_dns_aaaa_record_on_launch = (Optional) Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records. Default: false.
    enable_resource_name_dns_a_record_on_launch    = (Optional) Indicates whether to respond to DNS queries for instance hostnames with DNS A records. Default: false.
    ipv6_cidr_block                                = (Optional) The IPv6 network range for the subnet, in CIDR notation. The subnet size must use a /64 prefix length.
    ipv6_native                                    = (Optional) Indicates whether to create an IPv6-only subnet. Default: false.
    map_customer_owned_ip_on_launch                = (Optional) Specify true to indicate that network interfaces created in the subnet should be assigned a customer owned IP address. The customer_owned_ipv4_pool and outpost_arn arguments must be specified when set to true. Default is false.
    map_public_ip_on_launch                        = (Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is false.
    outpost_arn                                    = (Optional) The Amazon Resource Name (ARN) of the Outpost.
    private_dns_hostname_type_on_launch            = (Optional) The type of hostnames to assign to instances in the subnet at launch. For IPv6-only subnets, an instance DNS name must be based on the instance ID. For dual-stack and IPv4-only subnets, you can specify whether DNS names use the instance IPv4 address or the instance ID. Valid values: ip-name, resource-name.
    tags                                           = (Optional) A map of tags to assign to the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  EOF
  default     = {}
}

variable "virtual_private_cloud" {
  type = object({
    cidr_block                           = optional(string)
    instance_tenancy                     = optional(string)
    ipv4_ipam_pool_id                    = optional(string)
    ipv4_netmask_length                  = optional(number)
    ipv6_cidr_block                      = optional(string)
    ipv6_ipam_pool_id                    = optional(string)
    ipv6_netmask_length                  = optional(number)
    ipv6_cidr_block_network_border_group = optional(string)
    assign_generated_ipv6_cidr_block     = optional(bool)
    enable_dns_hostnames                 = optional(bool)
    enable_dns_support                   = optional(bool)
    enable_network_address_usage_metrics = optional(bool)
    tags                                 = optional(map(string))
  })
  description = <<EOF
    cidr_block                            = (Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using ipv4_netmask_length.
    instance_tenancy                      = (Optional) A tenancy option for instances launched into the VPC. Default is default, which ensures that EC2 instances launched in this VPC use the EC2 instance tenancy attribute specified when the EC2 instance is launched. The only other option is dedicated, which ensures that EC2 instances launched in this VPC are run on dedicated tenancy instances regardless of the tenancy attribute specified at launch. This has a dedicated per region fee of $2 per hour, plus an hourly per instance usage fee.
    ipv4_ipam_pool_id                     = (Optional) The ID of an IPv4 IPAM pool you want to use for allocating this VPC's CIDR. IPAM is a VPC feature that you can use to automate your IP address management workflows including assigning, tracking, troubleshooting, and auditing IP addresses across AWS Regions and accounts. Using IPAM you can monitor IP address usage throughout your AWS Organization.
    ipv4_netmask_length                   = (Optional) The netmask length of the IPv4 CIDR you want to allocate to this VPC. Requires specifying a ipv4_ipam_pool_id.
    ipv6_cidr_block                       = (Optional) IPv6 CIDR block to request from an IPAM Pool. Can be set explicitly or derived from IPAM using ipv6_netmask_length.
    ipv6_ipam_pool_id                     = (Optional) IPAM Pool ID for a IPv6 pool. Conflicts with assign_generated_ipv6_cidr_block.
    ipv6_netmask_length                   = (Optional) Netmask length to request from IPAM Pool. Conflicts with ipv6_cidr_block. This can be omitted if IPAM pool as a allocation_default_netmask_length set. Valid values: 56.
    ipv6_cidr_block_network_border_group  = (Optional) By default when an IPv6 CIDR is assigned to a VPC a default ipv6_cidr_block_network_border_group will be set to the region of the VPC. This can be changed to restrict advertisement of public addresses to specific Network Border Groups such as LocalZones.
    assign_generated_ipv6_cidr_block      = (Optional) Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block. Default is false. Conflicts with ipv6_ipam_pool_id
    enable_dns_hostnames                  = (Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false.
    enable_dns_support                    = (Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults to true.
    enable_network_address_usage_metrics  = (Optional) Indicates whether Network Address Usage metrics are enabled for your VPC. Defaults to false.
    tags                                  = (Optional) A map of tags to assign to the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.
  EOF
  nullable    = false
}
