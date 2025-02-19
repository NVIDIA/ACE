variable "compute_instance_groups" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group"
  type = map(object({
    name        = optional(string)
    description = optional(string)
    instances   = optional(list(string))
    named_ports = optional(list(object({
      name = string
      port = number
    })))
    network = optional(string)
    zone    = optional(string)
  }))
  default = {}
}

variable "compute_region_security_policies" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_security_policy" # TODO this is a beta resource
  type = map(object({
    name = optional(string)
    ddos_protection_config = optional(object({
      ddos_protection = string
    }))
    description = optional(string)
    region      = optional(string)
    type        = optional(string)
    user_defined_fields = optional(list(object({
      base   = string
      name   = string
      mask   = optional(string)
      offset = optional(number)
      size   = optional(number)
    })))
  }))
  default = {}
}

variable "compute_region_security_policy_rules" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_security_policy_rule" # TODO this is a beta resource
  type = map(object({
    action          = string
    priority        = number
    region          = string
    security_policy = string
    description     = optional(string)
    match = optional(object({
      config = optional(object({
        src_ip_ranges = optional(set(string))
      }))
      expr = optional(object({
        expression = string
      }))
      versioned_expr = optional(string)
    }))
    network_match = optional(object({
      dest_ip_ranges   = optional(set(string))
      dest_ports       = optional(list(string))
      ip_protocols     = optional(set(string))
      src_asns         = optional(list(string))
      src_ip_ranges    = optional(set(string))
      src_region_codes = optional(list(string))
      src_ports        = optional(list(string))
      user_defined_fields = optional(object({
        name  = optional(string)
        value = optional(string)
      }))
    }))
    preconfigured_waf_config = optional(object({
      exclusion = optional(object({
        target_rule_set = string
        target_rule_ids = optional(list(string))
        request_header = optional(object({
          operator = string
          value    = optional(string)
        }))
        request_cookie = optional(object({
          operator = string
          value    = optional(string)
        }))
        request_uri = optional(object({
          operator = string
          value    = optional(string)
        }))
        request_query_param = optional(object({
          operator = string
          value    = optional(string)
        }))
      }))
    }))
    preview = optional(bool)
    rate_limit_options = optional(object({
      ban_duration_sec = optional(number)
      ban_threshold = optional(object({
        count        = optional(number)
        interval_sec = optional(number)
      }))
      conform_action = optional(string)
      enforce_on_key = optional(string)
      enforce_on_key_configs = optional(object({
        enforce_on_key_type = optional(string)
        enforce_on_key_name = optional(string)
      }))
      enforce_on_key_name = optional(string)
      exceed_action       = optional(string)
      rate_limit_threshold = optional(object({
        count        = optional(number)
        interval_sec = optional(number)
      }))
    }))
  }))
  default = {}
}

variable "compute_region_health_checks" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_health_check"
  type = map(object({
    name               = optional(string)
    check_interval_sec = optional(number)
    description        = optional(string)
    grpc_health_check = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      grpc_service_name  = optional(string)
    }))
    healthy_threshold = optional(number)
    http_health_check = optional(object({
      host               = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      proxy_header       = optional(string)
      request_path       = optional(string)
      response           = optional(string)
    }))
    https_health_check = optional(object({
      host               = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      proxy_header       = optional(string)
      request_path       = optional(string)
      response           = optional(string)
    }))
    http2_health_check = optional(object({
      host               = optional(string)
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      proxy_header       = optional(string)
      request_path       = optional(string)
      response           = optional(string)
    }))
    log_config = optional(object({
      enable = optional(bool)
    }))
    region = optional(string)
    ssl_health_check = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      proxy_header       = optional(string)
      request            = optional(string)
      response           = optional(string)
    }))
    tcp_health_check = optional(object({
      port               = optional(number)
      port_name          = optional(string)
      port_specification = optional(string)
      proxy_header       = optional(string)
      request            = optional(string)
      response           = optional(string)
    }))
    timeout_sec         = optional(number)
    unhealthy_threshold = optional(number)
  }))
  default = {}
}

variable "compute_region_backend_services" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_backend_service"
  type = map(object({
    name                    = optional(string)
    affinity_cookie_ttl_sec = optional(number)
    backend = optional(object({
      balancing_mode               = optional(string)
      capacity_scaler              = optional(number)
      description                  = optional(string)
      failover                     = optional(string)
      group                        = optional(string)
      max_connections              = optional(number)
      max_connections_per_endpoint = optional(number)
      max_connections_per_instance = optional(number)
      max_rate                     = optional(number)
      max_rate_per_endpoint        = optional(number)
      max_rate_per_instance        = optional(number)
      max_utilization              = optional(number)
    }))
    cdn_policy = optional(object({
      cache_key_policy = optional(object({
        include_host           = optional(bool)
        include_named_cookies  = optional(bool)
        include_protocol       = optional(bool)
        include_query_string   = optional(bool)
        query_string_blacklist = optional(list(string))
        query_string_whitelist = optional(list(string))
      }))
      cache_mode       = optional(string)
      client_ttl       = optional(number)
      default_ttl      = optional(number)
      max_ttl          = optional(number)
      negative_caching = optional(bool)
      negative_caching_policy = optional(object({
        code = optional(number)
      }))
      serve_while_stale            = optional(bool)
      signed_url_cache_max_age_sec = optional(number)
    }))
    circuit_breakers = optional(object({
      max_connections             = optional(number)
      max_pending_requests        = optional(number)
      max_requests                = optional(number)
      max_requests_per_connection = optional(number)
      max_retries                 = optional(number)
    }))
    connection_draining_timeout_sec = optional(number)
    consistent_hash = optional(object({
      http_cookie = optional(object({
        name = optional(string)
        path = optional(string)
        ttl = optional(object({
          seconds = number
          nanos   = optional(number)
        }))
      }))
      http_header_name  = optional(string)
      minimum_ring_size = optional(number)
    }))
    description = optional(string)
    enable_cdn  = optional(bool)
    failover_policy = optional(object({
      disable_connection_drain_on_failover = optional(bool)
      drop_traffic_if_unhealthy            = optional(bool)
      failover_ratio                       = optional(number)
    }))
    health_checks = optional(list(string))
    iap = optional(object({
      enabled                     = bool
      oauth2_client_id            = optional(string)
      oauth2_client_secret        = optional(string)
      oauth2_client_secret_sha256 = optional(string)
    }))
    load_balancing_scheme = optional(string)
    locality_lb_policy    = optional(string)
    log_config = optional(object({
      enable      = optional(bool)
      sample_rate = optional(number)
    }))
    network = optional(string)
    outlier_detection = optional(object({
      base_ejection_time = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
      consecutive_errors                    = optional(number)
      consecutive_gateway_failure           = optional(number)
      enforcing_consecutive_errors          = optional(number)
      enforcing_consecutive_gateway_failure = optional(number)
      enforcing_success_rate                = optional(number)
      interval = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
      max_ejection_percent        = optional(number)
      success_rate_minimum_hosts  = optional(number)
      success_rate_request_volume = optional(number)
      success_rate_stdev_factor   = optional(number)
    }))
    port_name        = optional(string)
    protocol         = optional(string)
    security_policy  = optional(string) # TODO this is a beta attribute
    region           = optional(string)
    session_affinity = optional(string)
    timeout_sec      = optional(number)
  }))
  default = {}
}

variable "compute_addresses" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address"
  type = map(object({
    name               = optional(string)
    address            = optional(string)
    address_type       = optional(string)
    description        = optional(string)
    ipv6_endpoint_type = optional(string)
    ip_version         = optional(string)
    network            = optional(string)
    network_tier       = optional(string)
    prefix_length      = optional(number)
    purpose            = optional(string)
    region             = optional(string)
    subnetwork         = optional(string)
  }))
  default = {}
}

variable "compute_region_url_maps" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_url_map"
  type = map(object({
    name = optional(string)
    default_route_action = optional(object({
      cors_policy = optional(object({
        allow_credentials    = optional(bool)
        allow_headers        = optional(list(string))
        allow_methods        = optional(list(string))
        allow_origins        = optional(list(string))
        allow_origin_regexes = optional(list(string))
        disabled             = optional(bool)
        expose_headers       = optional(list(string))
        max_age              = optional(number)
      }))
      fault_injection_policy = optional(object({
        abort = optional(object({
          http_status = optional(number)
          percentage  = optional(number)
        }))
        delay = optional(object({
          fixed_delay = optional(object({
            nanos   = optional(number)
            seconds = optional(number)
          }))
          percentage = optional(number)
        }))
      }))
      request_mirror_policy = optional(object({
        backend_service = optional(string)
      }))
      retry_policy = optional(object({
        num_retries = optional(number)
        per_try_timeout = optional(object({
          nanos   = optional(number)
          seconds = optional(number)
        }))
        retry_conditions = optional(list(string))
      }))
      timeout = optional(object({
        nanos   = optional(number)
        seconds = optional(number)
      }))
      url_rewrite = optional(object({
        host_rewrite        = optional(string)
        path_prefix_rewrite = optional(string)
      }))
      weighted_backend_services = optional(list(object({
        backend_service = optional(string)
        header_action = optional(object({
          request_headers_to_add = optional(object({
            header_name  = string
            header_value = string
            replace      = string
          }))
          request_headers_to_remove = optional(list(string))
          response_headers_to_add = optional(object({
            header_name  = string
            header_value = string
            replace      = string
          }))
          response_headers_to_remove = optional(list(string))
        }))
        weight = optional(number)
      })))
    }))
    default_service = optional(string)
    default_url_redirect = optional(object({
      strip_query            = bool
      host_redirect          = optional(string)
      https_redirect         = optional(bool)
      path_redirect          = optional(string)
      prefix_redirect        = optional(string)
      redirect_response_code = optional(number)
    }))
    description = optional(string)
    host_rule = optional(object({
      hosts        = list(string)
      path_matcher = string
      description  = optional(string)
    }))
    path_matcher = optional(object({
      name            = string
      default_service = optional(string)
      default_url_redirect = optional(object({
        strip_query            = bool
        host_redirect          = optional(string)
        https_redirect         = optional(bool)
        path_redirect          = optional(string)
        prefix_redirect        = optional(string)
        redirect_response_code = optional(number)
      }))
      description = optional(string)
      route_rules = optional(list(object({
        priority = number
        header_action = optional(object({
          request_headers_to_add = optional(object({
            header_name  = string
            header_value = string
            replace      = string
          }))
          request_headers_to_remove = optional(list(string))
          response_headers_to_add = optional(object({
            header_name  = string
            header_value = string
            replace      = string
          }))
          response_headers_to_remove = optional(list(string))
        }))
        match_rules = optional(object({
          full_path_match = optional(string)
          header_matches = optional(list(object({
            header_name   = string
            exact_match   = optional(string)
            invert_match  = optional(string)
            prefix_match  = optional(string)
            present_match = optional(string)
            range_match = optional(object({
              range_end   = string
              range_start = string
            }))
            regex_match  = optional(string)
            suffix_match = optional(string)
          })))
          ignore_case = optional(bool)
          metadata_filters = optional(object({
            filter_labels = list(object({
              name  = string
              value = string
            }))
            filter_match_criteria = string
          }))
          path_template_match = optional(string)
          prefix_match        = optional(string)
          query_parameter_matches = optional(list(object({
            name          = string
            exact_match   = optional(string)
            present_match = optional(string)
            regex_match   = optional(string)
          })))
          regex_match = optional(string)
        }))
        route_action = optional(object({
          cors_policy = optional(object({
            allow_credentials    = optional(bool)
            allow_headers        = optional(list(string))
            allow_methods        = optional(list(string))
            allow_origins        = optional(list(string))
            allow_origin_regexes = optional(list(string))
            disabled             = optional(bool)
            expose_headers       = optional(list(string))
            max_age              = optional(number)
          }))
          fault_injection_policy = optional(object({
            abort = optional(object({
              http_status = optional(number)
              percentage  = optional(number)
            }))
            delay = optional(object({
              fixed_delay = optional(object({
                seconds = number
                nanos   = optional(number)
              }))
              percentage = optional(number)
            }))
          }))
          request_mirror_policy = optional(object({
            backend_service = string
          }))
          retry_policy = optional(object({
            num_retries = number
            per_try_timeout = optional(object({
              seconds = number
              nanos   = optional(number)
            }))
            retry_conditions = optional(list(string))
          }))
          timeout = optional(object({
            seconds = number
            nanos   = optional(number)
          }))
          url_rewrite = optional(object({
            host_rewrite          = optional(string)
            path_prefix_rewrite   = optional(string)
            path_template_rewrite = optional(string)
          }))
          weighted_backend_services = optional(list(object({
            backend_service = string
            weight          = number
            header_action = optional(object({
              request_headers_to_add = optional(object({
                header_name  = string
                header_value = string
                replace      = string
              }))
              request_headers_to_remove = optional(list(string))
              response_headers_to_add = optional(object({
                header_name  = string
                header_value = string
                replace      = string
              }))
              response_headers_to_remove = optional(list(string))
            }))
          })))
        }))
        service = optional(string)
        url_redirect = optional(object({
          host_redirect          = optional(string)
          https_redirect         = optional(bool)
          path_redirect          = optional(string)
          prefix_redirect        = optional(string)
          redirect_response_code = optional(number)
          strip_query            = optional(bool)
        }))
      })))
      path_rule = optional(list(object({
        paths = list(string)
        route_action = optional(object({
          cors_policy = optional(object({
            allow_credentials    = optional(bool)
            allow_headers        = optional(list(string))
            allow_methods        = optional(list(string))
            allow_origins        = optional(list(string))
            allow_origin_regexes = optional(list(string))
            disabled             = optional(bool)
            expose_headers       = optional(list(string))
            max_age              = optional(number)
          }))
          fault_injection_policy = optional(object({
            abort = optional(object({
              http_status = optional(number)
              percentage  = optional(number)
            }))
            delay = optional(object({
              fixed_delay = optional(object({
                seconds = number
                nanos   = optional(number)
              }))
              percentage = optional(number)
            }))
          }))
          request_mirror_policy = optional(object({
            backend_service = string
          }))
          retry_policy = optional(object({
            num_retries = number
            per_try_timeout = optional(object({
              seconds = number
              nanos   = optional(number)
            }))
            retry_conditions = optional(list(string))
          }))
          timeout = optional(object({
            seconds = number
            nanos   = optional(number)
          }))
          url_rewrite = optional(object({
            host_rewrite        = optional(string)
            path_prefix_rewrite = optional(string)
          }))
          weighted_backend_services = optional(list(object({
            backend_service = string
            weight          = number
            header_action = optional(object({
              request_headers_to_add = optional(object({
                header_name  = string
                header_value = string
                replace      = string
              }))
              request_headers_to_remove = optional(list(string))
              response_headers_to_add = optional(object({
                header_name  = string
                header_value = string
                replace      = string
              }))
              response_headers_to_remove = optional(list(string))
            }))
          })))
        }))
        service = optional(string)
        url_redirect = optional(object({
          strip_query            = bool
          host_redirect          = optional(string)
          https_redirect         = optional(bool)
          path_redirect          = optional(string)
          prefix_redirect        = optional(string)
          redirect_response_code = optional(number)
        }))
      })))
    }))
    region = optional(string)
    test = optional(object({
      host        = string
      path        = string
      service     = string
      description = optional(string)
    }))
  }))
  default = {}
}

variable "compute_region_target_http_proxies" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_target_http_proxy"
  type = map(object({
    url_map     = string
    name        = optional(string)
    description = optional(string)
    region      = optional(string)
  }))
  default = {}
}

variable "compute_forwarding_rules" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule"
  type = map(object({
    name                    = optional(string)
    allow_global_access     = optional(bool)
    allow_psc_global_access = optional(bool)
    all_ports               = optional(bool)
    backend_service         = optional(string)
    description             = optional(string)
    ip_address              = optional(string)
    is_mirroring_collector  = optional(bool)
    ip_protocol             = optional(string)
    ip_version              = optional(string)
    load_balancing_scheme   = optional(string)
    network                 = optional(string)
    network_tier            = optional(string)
    no_automate_dns_zone    = optional(bool)
    port_range              = optional(string)
    ports                   = optional(list(string))
    recreate_closed_psc     = optional(bool)
    region                  = optional(string)
    service_directory_registrations = optional(object({
      namespace = optional(string)
      service   = optional(string)
    }))
    service_label    = optional(string)
    source_ip_ranges = optional(list(string))
    subnetwork       = optional(string)
    target           = optional(string)
  }))
  default = {}
}