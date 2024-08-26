
resource "google_compute_network" "this" {
  name                    = var.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  for_each                 = { for subnet in var.subnets : subnet.name => subnet }
  name                     = format("%s-%s", var.name, each.key)
  region                   = var.region
  ip_cidr_range            = each.value["ip_cidr_range"]
  private_ip_google_access = each.value["private_ip_google_access"]
  network                  = google_compute_network.this.id
}

resource "google_compute_router" "this" {
  name    = format("%s-router", var.name)
  network = google_compute_network.this.name
  region  = var.region
  dynamic "bgp" {
    for_each = var.router_bgp == null ? [] : [var.router_bgp]
    content {
      advertise_mode     = bgp.value["advertise_mode"]
      advertised_groups  = bgp.value["advertised_groups"]
      asn                = bgp.value["asn"]
      keepalive_interval = bgp.value["keepalive_interval"]
    }
  }
}

resource "google_compute_address" "nat" {
  name   = format("%s-nat-public-ip", var.name)
  region = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = format("%s-nat", var.name)
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ips                            = [google_compute_address.nat.id]
  dynamic "subnetwork" {
    for_each = [for subnet in var.subnets : subnet.name if subnet.private]
    content {
      name                    = google_compute_subnetwork.this[subnetwork.value].id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
  log_config {
    enable = false
    filter = "ALL"
  }
  min_ports_per_vm                    = 64
  enable_endpoint_independent_mapping = false
}

resource "google_compute_firewall" "this" {
  for_each = { for firewall in var.firewalls : firewall.name => firewall }
  name     = each.key
  network  = google_compute_network.this.name
  priority = each.value["priority"]
  dynamic "allow" {
    for_each = each.value["allow"]
    content {
      protocol = allow.value["protocol"]
      ports    = allow.value["ports"]
    }
  }
  source_ranges = each.value["nat_source"] ? concat(each.value["source_ranges"], [format("%s/32", google_compute_address.nat.address)]) : each.value["source_ranges"]
  source_tags   = each.value["source_tags"]
  target_tags   = each.value["target_tags"]
}