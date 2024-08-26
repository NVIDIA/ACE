
resource "azurerm_public_ip" "public_ip" {
  for_each            = { for frontend_ip_configuration in var.frontend_ip_configurations : frontend_ip_configuration.public_ip_name => frontend_ip_configuration }
  name                = each.key
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.additional_tags
}

resource "azurerm_application_gateway" "application_gateway" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.region
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value["name"]
      ip_addresses = backend_address_pool.value["ip_addresses"]
    }
  }
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = backend_http_settings.value["name"]
      pick_host_name_from_backend_address = backend_http_settings.value["pick_host_name_from_backend_address"]
      host_name                           = backend_http_settings.value["host_name"]
      port                                = backend_http_settings.value["port"]
      protocol                            = backend_http_settings.value["protocol"]
      path                                = backend_http_settings.value["path"]
      affinity_cookie_name                = backend_http_settings.value["affinity_cookie_name"]
      cookie_based_affinity               = backend_http_settings.value["cookie_based_affinity"]
      probe_name                          = backend_http_settings.value["probe_name"]
      request_timeout                     = backend_http_settings.value["request_timeout"]
      trusted_root_certificate_names      = backend_http_settings.value["trusted_root_certificate_names"]
    }
  }
  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configurations
    content {
      name                 = frontend_ip_configuration.value["name"]
      public_ip_address_id = azurerm_public_ip.public_ip[frontend_ip_configuration.value["public_ip_name"]].id
    }
  }
  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = frontend_port.value["name"]
      port = frontend_port.value["port"]
    }
  }
  dynamic "gateway_ip_configuration" {
    for_each = var.gateway_ip_configurations
    content {
      name      = gateway_ip_configuration.value["name"]
      subnet_id = gateway_ip_configuration.value["subnet_id"]
    }
  }
  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = http_listener.value["name"]
      protocol                       = http_listener.value["protocol"]
      frontend_ip_configuration_name = http_listener.value["frontend_ip_configuration_name"]
      frontend_port_name             = http_listener.value["frontend_port_name"]
      host_names                     = http_listener.value["host_names"]
      require_sni                    = http_listener.value["require_sni"]
      ssl_certificate_name           = http_listener.value["ssl_certificate_name"]
    }
  }
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                       = request_routing_rule.value["name"]
      backend_address_pool_name  = request_routing_rule.value["backend_address_pool_name"]
      backend_http_settings_name = request_routing_rule.value["backend_http_settings_name"]
      http_listener_name         = request_routing_rule.value["http_listener_name"]
      priority                   = request_routing_rule.value["priority"]
      rule_type                  = request_routing_rule.value["rule_type"]
    }
  }
  sku {
    name     = var.sku["name"]
    tier     = var.sku["tier"]
    capacity = var.sku["capacity"]
  }
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      identity_ids = identity.value["identity_ids"]
      type         = identity.value["type"]
    }
  }
  dynamic "probe" {
    for_each = var.probes
    content {
      name                                      = probe.value["name"]
      pick_host_name_from_backend_http_settings = probe.value["pick_host_name_from_backend_http_settings"]
      host                                      = probe.value["host"]
      port                                      = probe.value["port"]
      protocol                                  = probe.value["protocol"]
      path                                      = probe.value["path"]
      timeout                                   = probe.value["timeout"]
      unhealthy_threshold                       = probe.value["unhealthy_threshold"]
      interval                                  = probe.value["interval"]
      minimum_servers                           = probe.value["minimum_servers"]
      match {
        status_code = probe.value["match"]["status_code"]
        body        = probe.value["match"]["body"]
      }
    }
  }
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.value["name"]
      key_vault_secret_id = ssl_certificate.value["key_vault_secret_id"]
    }
  }
  tags = var.additional_tags
}