resource "google_compute_network" "default" {
  for_each = var.virtual_private_clouds

  name = coalesce(each.value.name, each.key)

  auto_create_subnetworks                   = each.value.auto_create_subnetworks
  delete_default_routes_on_create           = each.value.delete_default_routes_on_create
  description                               = each.value.description
  enable_ula_internal_ipv6                  = each.value.enable_ula_internal_ipv6
  internal_ipv6_range                       = each.value.internal_ipv6_range
  mtu                                       = each.value.mtu
  #network_firewall_policy_enforcement_order = each.value.network_firewall_policy_enforcement_order
  routing_mode                              = each.value.routing_mode
}

resource "google_compute_subnetwork" "default" {
  for_each = var.subnets

  name    = coalesce(each.value.name, each.key)
  network = coalesce(try(google_compute_network.default[each.value.network].name, null), each.value.network)
  region  = coalesce(each.value.region, var.region)

  description                = each.value.description
  ip_cidr_range              = each.value.ip_cidr_range
  ipv6_access_type           = each.value.ipv6_access_type
  private_ip_google_access   = each.value.private_ip_google_access
  private_ipv6_google_access = each.value.private_ipv6_google_access
  purpose                    = each.value.purpose
  role                       = each.value.role
  stack_type                 = each.value.stack_type

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []

    content {
      aggregation_interval = log_config.value["aggregation_interval"]
      filter_expr          = log_config.value["filter_expr"]
      flow_sampling        = log_config.value["flow_sampling"]
      metadata             = log_config.value["metadata"]
      metadata_fields      = log_config.value["metadata"] == "CUSTOM_METADATA" ? log_config.value["metadata_fields"] : null
    }
  }

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_range != null ? each.value.secondary_ip_range : []

    content {
      ip_cidr_range = secondary_ip_range.value["ip_cidr_range"]
      range_name    = secondary_ip_range.value["range_name"]
    }
  }
}

resource "google_compute_router" "default" {
  for_each = var.routers

  name                          = coalesce(each.value.name, each.key)
  description                   = each.value.description
  encrypted_interconnect_router = each.value.encrypted_interconnect_router
  network                       = coalesce(each.value.network, try(google_compute_network.default[each.key].name, null))
  region                        = coalesce(each.value.region, var.region)

  dynamic "bgp" {
    for_each = each.value.bgp != null ? [each.value.bgp] : []

    content {
      asn                = bgp.value["asn"]
      advertise_mode     = bgp.value["advertise_mode"]
      advertised_groups  = bgp.value["advertised_groups"]
      keepalive_interval = bgp.value["keepalive_interval"]
      #identifier_range   = bgp.value["identifier_range"]

      dynamic "advertised_ip_ranges" {
        for_each = bgp.value["advertised_ip_ranges"] != null ? bgp.value["advertised_ip_ranges"] : []

        content {
          range       = advertised_ip_ranges.value["range"]
          description = advertised_ip_ranges.value["description"]
        }
      }
    }
  }
}

resource "google_compute_router_nat" "default" {
  for_each = var.nat_gateways

  drain_nat_ips                       = each.value.drain_nat_ips
  enable_dynamic_port_allocation      = each.value.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = each.value.enable_endpoint_independent_mapping
  #endpoint_types                      = each.value.endpoint_types
  icmp_idle_timeout_sec               = each.value.icmp_idle_timeout_sec
  name                                = coalesce(each.value.name, each.key)
  nat_ip_allocate_option              = each.value.nat_ip_allocate_option
  nat_ips                             = each.value.nat_ips
  max_ports_per_vm                    = each.value.max_ports_per_vm
  min_ports_per_vm                    = each.value.min_ports_per_vm
  region                              = coalesce(each.value.region, var.region)
  router                              = each.value.router
  source_subnetwork_ip_ranges_to_nat  = each.value.source_subnetwork_ip_ranges_to_nat
  tcp_established_idle_timeout_sec    = each.value.tcp_established_idle_timeout_sec
  #tcp_time_wait_timeout_sec           = each.value.tcp_time_wait_timeout_sec
  tcp_transitory_idle_timeout_sec     = each.value.tcp_transitory_idle_timeout_sec
  udp_idle_timeout_sec                = each.value.udp_idle_timeout_sec

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []

    content {
      enable = log_config.value["enable"]
      filter = log_config.value["filter"]
    }
  }

  dynamic "rules" {
    for_each = each.value.rules != null ? each.value.rules : []

    content {
      rule_number = rules.value["rule_number"]
      description = rules.value["description"]
      match       = rules.value["match"]

      dynamic "action" {
        for_each = rules.value["action"] != null ? [rules.value["action"]] : []

        content {
          source_nat_active_ips = action.value["source_nat_active_ips"]
          source_nat_drain_ips  = action.value["source_nat_drain_ips"]
        }
      }
    }
  }

  dynamic "subnetwork" {
    for_each = each.value.subnetwork != null ? each.value.subnetwork : []

    content {
      name                     = subnetwork.value["name"]
      source_ip_ranges_to_nat  = subnetwork.value["source_ip_ranges_to_nat"]
      secondary_ip_range_names = subnetwork.value["secondary_ip_range_names"]
    }
  }
}

resource "google_compute_route" "default" {
  for_each = var.routes

  name       = coalesce(each.value.name, each.key)
  network    = coalesce(each.value.network, try(google_compute_network.default[each.key].name, null))
  dest_range = each.value.dest_range

  description            = each.value.description
  next_hop_gateway       = each.value.next_hop_gateway
  next_hop_instance      = each.value.next_hop_instance
  next_hop_ip            = each.value.next_hop_ip
  next_hop_ilb           = each.value.next_hop_ilb
  next_hop_instance_zone = each.value.next_hop_instance_zone
  next_hop_vpn_tunnel    = each.value.next_hop_vpn_tunnel
  priority               = each.value.priority
  tags                   = each.value.tags
}

resource "google_compute_network_peering" "local_network_peering" {
  for_each = var.peering

  name         = "${each.key}-local"
  network      = google_compute_network.default[each.key].self_link
  peer_network = each.value.peer_network

  export_custom_routes                = each.value.export_custom_routes
  import_custom_routes                = each.value.import_custom_routes
  export_subnet_routes_with_public_ip = each.value.export_subnet_routes_with_public_ip
  import_subnet_routes_with_public_ip = each.value.import_subnet_routes_with_public_ip
  #stack_type                          = each.value.stack_type
}

resource "google_compute_network_peering" "peer_network_peering" {
  for_each = var.peering

  name         = "${each.key}-peer"
  network      = each.value.peer_network
  peer_network = google_compute_network.default[each.key].self_link

  export_custom_routes                = each.value.export_custom_routes
  import_custom_routes                = each.value.import_custom_routes
  export_subnet_routes_with_public_ip = each.value.export_subnet_routes_with_public_ip
  import_subnet_routes_with_public_ip = each.value.import_subnet_routes_with_public_ip
  #stack_type                          = each.value.stack_type
}

# resource "google_network_security_address_group" "default" {
#   for_each = var.network_security_address_groups

#   type     = each.value.type
#   capacity = each.value.capacity

#   name        = coalesce(each.value.name, each.key)
#   location    = each.value.location
#   description = each.value.description
#   labels      = each.value.labels
#   items       = each.value.items
#   parent      = each.value.parent
# }

resource "google_compute_address" "default" {
  for_each = var.ip_addresses

  name   = coalesce(each.value.name, each.key)
  region = coalesce(each.value.region, var.region)

  address            = each.value.address
  address_type       = each.value.address_type
  description        = each.value.description
  #ipv6_endpoint_type = each.value.ipv6_endpoint_type
  #ip_version         = each.value.ip_version
  #labels             = each.value.labels
  network            = each.value.network
  network_tier       = each.value.network_tier
  prefix_length      = each.value.prefix_length
  purpose            = each.value.purpose
  subnetwork         = each.value.subnetwork
}
