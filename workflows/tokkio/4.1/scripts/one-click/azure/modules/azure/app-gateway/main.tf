resource "azurerm_public_ip" "public_ip" {
  for_each = {
    for frontend_ip_configuration in var.frontend_ip_configurations :
    frontend_ip_configuration.public_ip_address.name => frontend_ip_configuration.public_ip_address
    if frontend_ip_configuration.public_ip_address != null
  }
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = each.value["allocation_method"]
  sku                 = each.value["sku"]
}

resource "azurerm_application_gateway" "application_gateway" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = backend_address_pool.value["name"]
      fqdns        = backend_address_pool.value["fqdns"]
      ip_addresses = backend_address_pool.value["ip_addresses"]
    }
  }
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                 = backend_http_settings.value["name"]
      port                 = backend_http_settings.value["port"]
      protocol             = backend_http_settings.value["protocol"]
      affinity_cookie_name = backend_http_settings.value["affinity_cookie_name"]
      dynamic "authentication_certificate" {
        for_each = toset(backend_http_settings.value["authentication_certificate"])
        content {
          name = authentication_certificate.value["name"]
        }
      }
      dynamic "connection_draining" {
        for_each = backend_http_settings.value["connection_draining"] != null ? toset([backend_http_settings.value["connection_draining"]]) : []
        content {
          enabled           = connection_draining.value["enabled"]
          drain_timeout_sec = connection_draining.value["drain_timeout_sec"]
        }
      }
      cookie_based_affinity               = backend_http_settings.value["cookie_based_affinity"]
      host_name                           = backend_http_settings.value["host_name"]
      path                                = backend_http_settings.value["path"]
      pick_host_name_from_backend_address = backend_http_settings.value["pick_host_name_from_backend_address"]
      probe_name                          = backend_http_settings.value["probe_name"]
      request_timeout                     = backend_http_settings.value["request_timeout"]
      trusted_root_certificate_names      = backend_http_settings.value["trusted_root_certificate_names"]
    }
  }
  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configurations
    content {
      name                            = frontend_ip_configuration.value["name"]
      private_ip_address              = frontend_ip_configuration.value["private_ip_address"]
      private_ip_address_allocation   = frontend_ip_configuration.value["private_ip_address_allocation"]
      private_link_configuration_name = frontend_ip_configuration.value["private_link_configuration_name"]
      public_ip_address_id            = try(azurerm_public_ip.public_ip[frontend_ip_configuration.value["public_ip_address"]["name"]].id, frontend_ip_configuration.value["public_ip_address_id"])
      subnet_id                       = frontend_ip_configuration.value["subnet_id"]
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
      frontend_ip_configuration_name = http_listener.value["frontend_ip_configuration_name"]
      frontend_port_name             = http_listener.value["frontend_port_name"]
      protocol                       = http_listener.value["protocol"]
      dynamic "custom_error_configuration" {
        for_each = toset(http_listener.value["custom_error_configuration"])
        content {
          status_code           = custom_error_configuration.value["status_code"]
          custom_error_page_url = custom_error_configuration.value["custom_error_page_url "]
        }
      }
      host_names           = http_listener.value["host_names"]
      require_sni          = http_listener.value["require_sni"]
      ssl_certificate_name = http_listener.value["ssl_certificate_name"]
      firewall_policy_id   = http_listener.value["firewall_policy_id"]
      ssl_profile_name     = http_listener.value["ssl_profile_name"]
    }
  }
  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                        = request_routing_rule.value["name"]
      http_listener_name          = request_routing_rule.value["http_listener_name"]
      rule_type                   = request_routing_rule.value["rule_type"]
      backend_address_pool_name   = request_routing_rule.value["backend_address_pool_name"]
      backend_http_settings_name  = request_routing_rule.value["backend_http_settings_name"]
      priority                    = request_routing_rule.value["priority"]
      redirect_configuration_name = request_routing_rule.value["redirect_configuration_name"]
      rewrite_rule_set_name       = request_routing_rule.value["rewrite_rule_set_name"]
      url_path_map_name           = request_routing_rule.value["url_path_map_name"]
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
      type         = identity.value["type"]
      identity_ids = identity.value["identity_ids"]
    }
  }
  dynamic "probe" {
    for_each = var.probes
    content {
      interval            = probe.value["interval"]
      name                = probe.value["name"]
      path                = probe.value["path"]
      protocol            = probe.value["protocol"]
      timeout             = probe.value["timeout"]
      unhealthy_threshold = probe.value["unhealthy_threshold"]
      host                = probe.value["host"]
      dynamic "match" {
        for_each = probe.value["match"] != null ? toset([probe.value["match"]]) : []
        content {
          status_code = match.value["status_code"]
          body        = match.value["body"]
        }
      }
      minimum_servers                           = probe.value["minimum_servers"]
      pick_host_name_from_backend_http_settings = probe.value["pick_host_name_from_backend_http_settings"]
      port                                      = probe.value["port"]
    }
  }
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = ssl_certificate.value["name"]
      data                = ssl_certificate.value["data"]
      password            = ssl_certificate.value["password"]
      key_vault_secret_id = ssl_certificate.value["key_vault_secret_id"]
    }
  }
}