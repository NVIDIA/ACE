variable "network_security_groups" {
  description = <<EOF
  rules                                        = Manages a Network Security Rule.
    access                                     = (Required) Specifies whether network traffic is allowed or denied. Possible values are Allow and Deny.
    protocol                                   = (Required) Network protocol this rule applies to. Possible values include Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
    priority                                   = (Required) Specifies the priority of the rule. The value can be between 100 and 4096. The priority number must be unique for each rule in the collection. The lower the priority number, the higher the priority of the rule.
    direction                                  = (Required) The direction specifies if rule will be evaluated on incoming or outgoing traffic. Possible values are Inbound and Outbound.
    description                                = (Optional) A description for this rule. Restricted to 140 characters.
    source_port_ranges                         = (Optional) List of source ports or port ranges. This is required if source_port_range is not specified.
    destination_port_ranges                    = (Optional) List of destination ports or port ranges. This is required if destination_port_range is not specified.
    source_address_prefixes                    = (Optional) List of source address prefixes. Tags may not be used. This is required if source_address_prefix is not specified.
    source_application_security_group_ids      = (Optional) A List of source Application Security Group IDs
    destination_address_prefixes               = (Optional) List of destination address prefixes. Tags may not be used. This is required if destination_address_prefix is not specified.
    destination_application_security_group_ids = (Optional) A List of destination Application Security Group IDs
  EOF
  type = map(object({
    rules = map(object({
      access                                     = string
      direction                                  = string
      priority                                   = number
      protocol                                   = string
      description                                = optional(string)
      destination_address_prefixes               = optional(list(string))
      destination_application_security_group_ids = optional(list(string))
      destination_port_ranges                    = optional(list(string))
      source_port_ranges                         = optional(list(string))
      source_address_prefixes                    = optional(list(string))
      source_application_security_group_ids      = optional(list(string))
    }))
  }))
  default  = {}
  nullable = false
}

variable "location" {
  description = "(Required) Specifies the supported Azure location where the resource should exist. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "nat_gateways" {
  description = <<EOF
    idle_timeout_in_minutes = (Optional) The idle timeout which should be used in minutes. Defaults to 4.
    sku_name                = (Optional) The SKU which should be used. At this time the only supported value is Standard. Defaults to Standard.
    zones                   = (Optional) A list of Availability Zones in which this NAT Gateway should be located. Changing this forces a new NAT Gateway to be created.
  EOF
  type = map(object({
    idle_timeout_in_minutes = optional(number)
    public_ip_name          = optional(string)
    public_ip_prefix_name   = optional(string)
    sku_name                = optional(string)
    zones                   = optional(list(string))
  }))
  default  = {}
  nullable = false
}

variable "peers" {
  description = <<EOF
    resource_group_name          = (Required) The name of the resource group of the remote virtual network.
    allow_virtual_network_access = (Optional) Controls if the VMs in the remote virtual network can access VMs in the local virtual network. Defaults to true.
    allow_forwarded_traffic      = (Optional) Controls if forwarded traffic from VMs in the remote virtual network is allowed. Defaults to false.
    allow_gateway_transit        = (Optional) Controls gatewayLinks can be used in the remote virtual network’s link to the local virtual network. Defaults to false.
    direction                    = (Optional) determines the direction of peering. Options are Both, Inbound or Inbound.
    use_remote_gateways          = (Optional) Controls if remote gateways can be used on the local virtual network. If the flag is set to true, and allow_gateway_transit on the remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway. Defaults to false.
  EOF
  type = map(object({
    resource_group_name          = string
    allow_forwarded_traffic      = optional(bool, false)
    allow_gateway_transit        = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
    direction                    = optional(string, "Both")
    use_remote_gateways          = optional(bool, false)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue(
      [
        for peer in var.peers : contains(["Both", "Inbound", "Outbound"], title(peer.direction))
      ]
    )
    error_message = "Peer's direction must be either Both, Incoming or Outgoing."
  }
}

variable "public_ips" {
  description = <<EOF
    allocation_method       = (Required) Defines the allocation method for this IP address. Possible values are Static or Dynamic.
    ddos_protection_mode    = (Optional) The DDoS protection mode of the public IP. Possible values are Disabled, Enabled, and VirtualNetworkInherited. Defaults to VirtualNetworkInherited.
    ddos_protection_plan_id = (Optional) The ID of DDoS protection plan associated with the public IP.
    domain_name_label       = (Optional) Label for the Domain Name. Will be used to make up the FQDN. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system.
    edge_zone               = (Optional) Specifies the Edge Zone within the Azure Region where this Public IP should exist. Changing this forces a new Public IP to be created.
    idle_timeout_in_minutes = (Optional) Specifies the timeout for the TCP idle connection. The value can be set between 4 and 30 minutes.
    ip_tags                 = (Optional) A mapping of IP tags to assign to the public IP. Changing this forces a new resource to be created.
    ip_version              = (Optional) The IP Version to use, IPv6 or IPv4. Changing this forces a new resource to be created. Defaults to IPv4.
    public_ip_prefix_id     = (Optional) If specified then public IP address allocated will be provided from the public IP prefix resource. Changing this forces a new resource to be created.
    reverse_fqdn            = (Optional) A fully qualified domain name that resolves to this public IP address. If the reverseFqdn is specified, then a PTR DNS record is created pointing from the IP address in the in-addr.arpa domain to the reverse FQDN.
    sku                     = (Optional) The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic. Changing this forces a new resource to be created.
    sku_tier                = (Optional) The SKU Tier that should be used for the Public IP. Possible values are Regional and Global. Defaults to Regional. Changing this forces a new resource to be created.
    zones                   = (Optional) A collection containing the availability zone to allocate the Public IP in. Changing this forces a new resource to be created.
  EOF
  type = map(object({
    allocation_method       = string
    ddos_protection_mode    = optional(string)
    ddos_protection_plan_id = optional(string)
    domain_name_label       = optional(string)
    edge_zone               = optional(string)
    idle_timeout_in_minutes = optional(number)
    ip_tags                 = optional(map(string))
    ip_version              = optional(string)
    public_ip_prefix_name   = optional(string)
    reverse_fqdn            = optional(string)
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string)
    zones                   = optional(list(string))
  }))
  default  = {}
  nullable = false
}

variable "public_ip_prefixes" {
  description = <<EOF
    prefix_length = (Required) Specifies the number of bits of the prefix. The value can be set between 0 (4,294,967,296 addresses) and 31 (2 addresses). Changing this forces a new resource to be created.
    sku           = (Optional) The SKU of the Public IP Prefix. Accepted values are Standard. Defaults to Standard. Changing this forces a new resource to be created.
    ip_version    = (Optional) The IP Version to use, IPv6 or IPv4. Changing this forces a new resource to be created. Default is IPv4.
    zones         = (Optional) Specifies a list of Availability Zones in which this Public IP Prefix should be located. Changing this forces a new Public IP Prefix to be created.
  EOF
  type = map(object({
    prefix_length = number
    ip_version    = optional(string)
    sku           = optional(string)
    zones         = optional(list(string))
  }))
  default  = {}
  nullable = false
}

variable "resource_group_name" {
  description = "(Required) The name of the Resource Group where the resources should exist. Changing this forces new resources to be created."
  type        = string
  nullable    = false
}

variable "route_tables" {
  description = <<EOF
    name                          = (Required) The name of the route table. Changing this forces a new resource to be created.
    routes                        = (Optional) Map of route objects representing routes as defined below. Each object accepts the arguments documented below.
      address_prefix              = (Required) The destination to which the route applies. Can be CIDR (such as 10.1.0.0/16) or Azure Service Tag (such as ApiManagement, AzureBackup or AzureMonitor) format.
      next_hop_type               = (Required) The type of Azure hop the packet should be sent to. Possible values are VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance and None.
      next_hop_in_ip_address      = (Optional) Contains the IP address packets should be forwarded to. Next hop values are only allowed in routes where the next hop type is VirtualAppliance.
    disable_bgp_route_propagation = (Optional) Boolean flag which controls propagation of routes learned by BGP on that route table. True means disable.
  EOF
  type = map(object({
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = string
    })), {})
    disable_bgp_route_propagation = optional(bool)
  }))
  default  = {}
  nullable = false
}

variable "subnets" {
  description = <<EOF
  address_prefixes                              = (Required) The address prefixes to use for the subnet.
  delegations                                   = (Optional) One or more delegation blocks as defined below.
    service_delegation                          = (Required) A service_delegation block as defined below.
      name                                      = (Required) The name of service to delegate to.
      actions                                   = (Optional) A list of Actions which should be delegated. This list is specific to the service to delegate to.
  private_endpoint_network_policies_enabled     = (Optional) Enable or Disable network policies for the private endpoint on the subnet. Setting this to true will Enable the policy and setting this to false will Disable the policy. Defaults to true.
  private_link_service_network_policies_enabled = (Optional) Enable or Disable network policies for the private link service on the subnet. Setting this to true will Enable the policy and setting this to false will Disable the policy. Defaults to true.
  service_endpoints                             = (Optional) The list of Service endpoints to associate with the subnet.
  service_endpoint_policy_ids                   = (Optional) The list of IDs of Service Endpoint Policies to associate with the subnet.
  EOF
  type = map(object({
    address_prefixes = list(string)
    delegations = optional(map(object({
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    })), {})
    nat_gateway_name                              = optional(string)
    network_security_group_names                  = optional(set(string), [])
    private_endpoint_network_policies_enabled     = optional(bool)
    private_link_service_network_policies_enabled = optional(bool)
    route_table_name                              = optional(string)
    service_endpoints                             = optional(list(string))
    service_endpoint_policy_ids                   = optional(list(string))
  }))
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(string)
  default     = null
}

variable "virtual_network" {
  description = <<EOF
    name                    = (Required) The name of the virtual network. Changing this forces a new resource to be created.
    address_space           = (Required) The address space that is used the virtual network. You can supply more than one address space.
    bgp_community           = (Optional) The BGP community attribute in format <as-number>:<community-value>.
    ddos_protection_plan    = (Optional) A ddos_protection_plan block as documented below.
      id                    = (Required) The ID of DDoS Protection Plan.
      enable                = (Required) Enable/disable DDoS Protection Plan on Virtual Network.
    encryption              = (Optional) A encryption block as defined below.
      enforcement           = (Required) Specifies if the encrypted Virtual Network allows VM that does not support encryption. Possible values are DropUnencrypted and AllowUnencrypted.
    dns_servers             = (Optional) List of IP addresses of DNS servers
    edge_zone               = (Optional) Specifies the Edge Zone within the Azure Region where this Virtual Network should exist. Changing this forces a new Virtual Network to be created.
    flow_timeout_in_minutes = (Optional) The flow timeout in minutes for the Virtual Network, which is used to enable connection tracking for intra-VM flows. Possible values are between 4 and 30 minutes.
  EOF
  type = object({
    name          = string
    address_space = list(string)
    bgp_community = optional(string)
    ddos_protection_plan = optional(object({
      id     = string
      enable = bool
    }))
    encryption = optional(object({
      enforcement = string
    }))
    dns_servers             = optional(list(string))
    edge_zone               = optional(string)
    flow_timeout_in_minutes = optional(number)
  })
}
