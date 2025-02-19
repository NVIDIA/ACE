variable "firewall_policies" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network_firewall_policy"
  type = map(object({
    name              = optional(string)
    description       = optional(string)
    attachment_target = optional(string)
  }))
  default = {}
}

variable "firewall_policy_rules" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network_firewall_policy_rule"
  type = map(object({
    action          = string
    direction       = string
    firewall_policy = string
    match = list(object({
      dest_address_groups       = optional(list(string))
      dest_fqdns                = optional(list(string))
      dest_ip_ranges            = optional(list(string))
      dest_region_codes         = optional(list(string))
      dest_threat_intelligences = optional(list(string))
      layer4_configs = list(object({
        ip_protocol = string
        ports       = optional(list(string))
      }))
      src_address_groups = optional(list(string))
      src_fqdns          = optional(list(string))
      src_ip_ranges      = optional(list(string))
      src_region_codes   = optional(list(string))
      src_secure_tags = optional(map(object({
        name = string
      })))
      src_threat_intelligences = optional(list(string))
    }))
    priority                = number
    description             = optional(string)
    disabled                = optional(bool)
    enable_logging          = optional(bool)
    rule_name               = optional(string)
    security_profile_group  = optional(string)
    target_service_accounts = optional(list(string))
    tls_inspect             = optional(bool)
  }))
  default = {}
}

variable "firewall_rules" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall"
  type = map(object({
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })))
    description        = optional(string)
    destination_ranges = optional(list(string))
    direction          = optional(string)
    disabled           = optional(bool)
    log_config = optional(object({
      metadata = string
    }))
    name                    = optional(string)
    network                 = optional(string)
    priority                = optional(number)
    source_ranges           = optional(list(string))
    source_service_accounts = optional(list(string))
    source_tags             = optional(list(string))
    target_service_accounts = optional(list(string))
    target_tags             = optional(list(string))
  }))
  default = {}
}
