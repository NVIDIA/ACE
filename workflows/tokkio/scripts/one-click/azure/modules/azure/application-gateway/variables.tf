
variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "backend_address_pools" {
  type = list(object({
    name         = string
    ip_addresses = list(string)
  }))
}

variable "backend_http_settings" {
  type = list(object({
    name                                = string
    pick_host_name_from_backend_address = bool
    host_name                           = string
    port                                = number
    protocol                            = string
    path                                = string
    cookie_based_affinity               = string
    affinity_cookie_name                = string
    probe_name                          = string
    request_timeout                     = number
    trusted_root_certificate_names      = list(string)
  }))
}

variable "frontend_ip_configurations" {
  type = list(object({
    name           = string
    public_ip_name = string
  }))
}

variable "frontend_ports" {
  type = list(object({
    name = string
    port = number
  }))
}

variable "gateway_ip_configurations" {
  type = list(object({
    name      = string
    subnet_id = string
  }))
}

variable "http_listeners" {
  type = list(object({
    name                           = string
    protocol                       = string
    frontend_ip_configuration_name = string
    frontend_port_name             = string
    host_names                     = list(string)
    require_sni                    = bool
    ssl_certificate_name           = string
  }))
}

variable "request_routing_rules" {
  type = list(object({
    name                       = string
    backend_address_pool_name  = string
    backend_http_settings_name = string
    http_listener_name         = string
    priority                   = number
    rule_type                  = string
  }))
}

variable "sku" {
  type = object({
    name     = string
    tier     = string
    capacity = number
  })
}

variable "identity" {
  type = object({
    identity_ids = list(string)
    type         = string
  })
  default = null
}

variable "probes" {
  type = list(object({ name = string
    pick_host_name_from_backend_http_settings = bool
    host                                      = string
    port                                      = number
    protocol                                  = string
    path                                      = string
    timeout                                   = number
    unhealthy_threshold                       = number
    interval                                  = number
    minimum_servers                           = number
    match = object({
      status_code = list(string)
      body        = string
  }) }))
  default = []
}

variable "ssl_certificates" {
  type = list(object({
    name                = string
    key_vault_secret_id = string
  }))
  default = []
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}