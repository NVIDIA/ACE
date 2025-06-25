resource "google_compute_network_firewall_policy" "default" {
  provider = google

  for_each = var.firewall_policies

  name = coalesce(each.value.name, each.key)

  description = each.value.description
}

resource "google_compute_network_firewall_policy_association" "default" {
  provider = google

  for_each = var.firewall_policies

  name              = coalesce(each.value.name, each.key)
  attachment_target = each.value.attachment_target
  firewall_policy   = google_compute_network_firewall_policy.default[each.key].name
}

resource "google_compute_network_firewall_policy_rule" "default" {
  provider = google

  for_each = var.firewall_policy_rules

  action          = each.value.action
  direction       = each.value.direction
  firewall_policy = each.value.firewall_policy
  priority        = each.value.priority

  description             = each.value.description
  disabled                = each.value.disabled
  enable_logging          = each.value.enable_logging
  rule_name               = coalesce(each.value.rule_name, each.key)
  #security_profile_group  = each.value.security_profile_group
  target_service_accounts = each.value.target_service_accounts
  #tls_inspect             = each.value.tls_inspect

  dynamic "match" {
    for_each = each.value.match != null ? each.value.match : []

    content {
      #dest_address_groups       = match.value["dest_address_groups"]
      #dest_fqdns                = match.value["dest_fqdns"]
      dest_ip_ranges            = match.value["dest_ip_ranges"]
      #dest_region_codes         = match.value["dest_region_codes"]
      #dest_threat_intelligences = match.value["dest_threat_intelligences"]
      #src_address_groups        = match.value["src_address_groups"]
      #src_fqdns                 = match.value["src_fqdns"]
      src_ip_ranges             = match.value["src_ip_ranges"]
      #src_region_codes          = match.value["src_region_codes"]
      #src_threat_intelligences  = match.value["src_threat_intelligences"]

      dynamic "layer4_configs" {
        for_each = match.value["layer4_configs"] != null ? match.value["layer4_configs"] : []

        content {
          ip_protocol = layer4_configs.value["ip_protocol"]
          ports       = layer4_configs.value["ports"]
        }
      }

      dynamic "src_secure_tags" {
        for_each = match.value["src_secure_tags"] != null ? match.value["src_secure_tags"] : []

        content {
          name = src_secure_tags.value["name"]
        }
      }
    }
  }
}

resource "google_compute_firewall" "default" {
  provider = google

  for_each = var.firewall_rules

  description = each.value.description
  name        = coalesce(each.value.name, each.key)
  network     = each.value.network

  destination_ranges      = each.value.destination_ranges
  direction               = each.value.direction
  disabled                = each.value.disabled
  priority                = each.value.priority
  source_ranges           = each.value.source_ranges
  source_service_accounts = each.value.source_service_accounts
  source_tags             = each.value.source_tags
  target_service_accounts = each.value.target_service_accounts
  target_tags             = each.value.target_tags

  dynamic "allow" {
    for_each = each.value.allow != null ? each.value.allow : []

    content {
      ports    = allow.value["ports"]
      protocol = allow.value["protocol"]
    }
  }

  dynamic "deny" {
    for_each = each.value.deny != null ? each.value.deny : []

    content {
      ports    = deny.value["ports"]
      protocol = deny.value["protocol"]
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []

    content {
      metadata = log_config.value["metadata"]
    }
  }
}