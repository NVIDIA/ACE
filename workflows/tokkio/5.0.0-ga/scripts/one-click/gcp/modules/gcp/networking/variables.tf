variable "region" {
  type        = string
  description = "(Required) The GCP region in which the resources belong to."
  nullable    = false
}

variable "ip_addresses" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address.html"
  type = map(object({
    address            = optional(string)
    address_type       = optional(string)
    description        = optional(string)
    ipv6_endpoint_type = optional(string)
    ip_version         = optional(string)
    labels             = optional(map(string))
    name               = optional(string)
    network            = optional(string)
    network_tier       = optional(string)
    prefix_length      = optional(number)
    purpose            = optional(string)
    region             = optional(string)
    subnetwork         = optional(string)
  }))
  default = {}
}

variable "nat_gateways" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat"
  type = map(object({
    source_subnetwork_ip_ranges_to_nat = string
    router                             = string
    name                               = optional(string)
    nat_ip_allocate_option             = optional(string)
    nat_ips                            = optional(list(string))
    drain_nat_ips                      = optional(list(string))
    subnetwork = optional(list(object({
      name                     = string
      source_ip_ranges_to_nat  = list(string)
      secondary_ip_range_names = optional(list(string))
    })))
    min_ports_per_vm                 = optional(number)
    max_ports_per_vm                 = optional(number)
    enable_dynamic_port_allocation   = optional(bool)
    udp_idle_timeout_sec             = optional(number)
    icmp_idle_timeout_sec            = optional(number)
    tcp_established_idle_timeout_sec = optional(number)
    tcp_transitory_idle_timeout_sec  = optional(number)
    tcp_time_wait_timeout_sec        = optional(number)
    log_config = optional(object({
      enable = bool
      filter = string
    }))
    endpoint_types = optional(list(string))
    rules = optional(list(object({
      rule_number = number
      description = optional(string)
      match       = string
      action = optional(object({
        source_nat_active_ips = optional(list(string))
        source_nat_drain_ips  = optional(list(string))
      }))
    })))
    enable_endpoint_independent_mapping = optional(bool)
    region                              = optional(string)
  }))
  default = {}
}

variable "network_security_address_groups" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_security_address_group"
  type = map(object({
    type        = string
    capacity    = number
    name        = optional(string)
    location    = string
    description = optional(string)
    labels      = optional(map(string))
    items       = optional(list(string))
    parent      = optional(string)
  }))
  default = {}
}

variable "routers" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router"
  type = map(object({
    name        = optional(string)
    network     = optional(string)
    description = optional(string)
    bgp = optional(object({
      asn               = number
      advertise_mode    = optional(string)
      advertised_groups = optional(list(string))
      advertised_ip_ranges = optional(list(object({
        range       = string
        description = optional(string)
      })))
      keepalive_interval = optional(number)
      identifier_range   = optional(string)
    }))
    encrypted_interconnect_router = optional(bool)
    region                        = optional(string)
  }))
  default = {}
}

variable "peering" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network_peering"
  type = map(object({
    peer_network                        = string
    export_custom_routes                = optional(bool)
    import_custom_routes                = optional(bool)
    export_subnet_routes_with_public_ip = optional(bool)
    import_subnet_routes_with_public_ip = optional(bool)
    stack_type                          = optional(string)
  }))
  default = {}
}

variable "routes" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route"
  type = map(object({
    dest_range             = string
    description            = optional(string)
    name                   = optional(string)
    network                = optional(string)
    next_hop_gateway       = optional(string)
    next_hop_instance      = optional(string)
    next_hop_ip            = optional(string)
    next_hop_ilb           = optional(string)
    next_hop_instance_zone = optional(string)
    next_hop_vpn_tunnel    = optional(string)
    priority               = optional(number)
    tags                   = optional(list(string))
  }))
  default = {}
}

variable "subnets" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork"
  type = map(object({
    ip_cidr_range    = string
    description      = optional(string)
    ipv6_access_type = optional(string)
    log_config = optional(object({
      aggregation_interval = optional(string)
      filter_expr          = optional(string)
      flow_sampling        = optional(string)
      metadata             = optional(string)
      metadata_fields      = optional(list(string))
    }))
    name                       = optional(string)
    network                    = optional(string)
    private_ip_google_access   = optional(string)
    private_ipv6_google_access = optional(string)
    purpose                    = optional(string)
    region                     = optional(string)
    role                       = optional(string)
    secondary_ip_range = optional(list(object({
      ip_cidr_range = string
      range_name    = string
    })))
    stack_type = optional(string)
  }))
  default = {}
}

variable "virtual_private_clouds" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network"
  type = map(object({
    name                                      = optional(string)
    description                               = optional(string)
    auto_create_subnetworks                   = optional(bool, false)
    delete_default_routes_on_create           = optional(bool)
    enable_ula_internal_ipv6                  = optional(bool)
    internal_ipv6_range                       = optional(string)
    mtu                                       = optional(number)
    network_firewall_policy_enforcement_order = optional(string)
    routing_mode                              = optional(string)
  }))
  default = {}
}
