resource "google_compute_instance_group" "default" {
  provider = google

  for_each = var.compute_instance_groups

  name = coalesce(each.value.name, each.key)

  description = each.value.description
  instances   = each.value.instances

  dynamic "named_port" {
    for_each = each.value.named_ports != null ? each.value.named_ports : []

    content {
      name = named_port.value["name"]
      port = named_port.value["port"]
    }
  }

  network = each.value.network
  zone    = each.value.zone
}

resource "google_compute_region_security_policy" "default" {
  provider = google-beta

  for_each = var.compute_region_security_policies

  name = coalesce(each.value.name, each.key)

  dynamic "ddos_protection_config" {
    for_each = each.value["ddos_protection_config"] != null ? [each.value["ddos_protection_config"]] : []

    content {
      ddos_protection = ddos_protection_config.value["ddos_protection"]
    }
  }

  description = each.value.description
  region      = each.value.region
  type        = each.value.type

  dynamic "user_defined_fields" {
    for_each = each.value["user_defined_fields"] != null ? each.value["user_defined_fields"] : []

    content {
      base   = user_defined_fields.value["base"]
      name   = user_defined_fields.value["name"]
      mask   = user_defined_fields.value["mask"]
      offset = user_defined_fields.value["offset"]
      size   = user_defined_fields.value["size"]
    }
  }
}

resource "google_compute_region_security_policy_rule" "default" {
  provider = google-beta

  for_each = var.compute_region_security_policy_rules

  action          = each.value.action
  priority        = each.value.priority
  region          = each.value.region
  security_policy = try(google_compute_region_security_policy.default[each.value.security_policy].name, each.value.security_policy)
  description     = each.value.description

  dynamic "match" {
    for_each = each.value.match != null ? [each.value.match] : []

    content {
      dynamic "config" {
        for_each = match.value["config"] != null ? [match.value["config"]] : []

        content {
          src_ip_ranges = config.value["src_ip_ranges"]
        }
      }

      dynamic "expr" {
        for_each = match.value["expr"] != null ? [match.value["expr"]] : []

        content {
          expression = expr.value["expression"]
        }
      }

      versioned_expr = match.value["versioned_expr"]
    }
  }

  #   dynamic "network_match" {
  #     for_each = each.value.network_match != null ? [each.value.network_match] : []
  #
  #     content {
  #       dest_ip_ranges   = network_match.value["dest_ip_ranges"]
  #       dest_ports       = network_match.value["dest_ports"]
  #       ip_protocols     = network_match.value["ip_protocols"]
  #       src_asns         = network_match.value["src_asns"]
  #       src_ip_ranges    = network_match.value["src_ip_ranges"]
  #       src_region_codes = network_match.value["src_region_codes"]
  #       src_ports        = network_match.value["src_ports"]
  #
  #       dynamic "user_defined_fields" {
  #         for_each = network_match.value["user_defined_fields"] != null ? [network_match.value["user_defined_fields"]] : []
  #
  #         content {
  #           name  = user_defined_fields.value["name"]
  #           value = user_defined_fields.value["value"]
  #         }
  #       }
  #     }
  #   }
  #
  #   dynamic "preconfigured_waf_config" {
  #     for_each = each.value.preconfigured_waf_config != null ? [each.value.preconfigured_waf_config] : []
  #
  #     content {
  #       target_rule_set = preconfigured_waf_config.value["target_rule_set"]
  #       target_rule_ids = preconfigured_waf_config.value["target_rule_ids"]
  #
  #       dynamic "request_header" {
  #         for_each = preconfigured_waf_config.value["request_header"] != null ? [preconfigured_waf_config.value["request_header"]] : []
  #
  #         content {
  #           operator = request_header.value["operator"]
  #           value    = request_header.value["value"]
  #         }
  #       }
  #
  #       dynamic "request_cookie" {
  #         for_each = preconfigured_waf_config.value["request_cookie"] != null ? [preconfigured_waf_config.value["request_cookie"]] : []
  #
  #         content {
  #           operator = request_cookie.value["operator"]
  #           value    = request_cookie.value["value"]
  #         }
  #       }
  #
  #       dynamic "request_uri" {
  #         for_each = preconfigured_waf_config.value["request_uri"] != null ? [preconfigured_waf_config.value["request_uri"]] : []
  #
  #         content {
  #           operator = request_uri.value["operator"]
  #           value    = request_uri.value["value"]
  #         }
  #       }
  #
  #       dynamic "request_query_param" {
  #         for_each = preconfigured_waf_config.value["request_query_param"] != null ? [preconfigured_waf_config.value["request_query_param"]] : []
  #
  #         content {
  #           operator = request_query_param.value["operator"]
  #           value    = request_query_param.value["value"]
  #         }
  #       }
  #     }
  #   }
  #
  #   preview = each.value.preview
  #
  #   dynamic "rate_limit_options" {
  #     for_each = each.value.rate_limit_options != null ? [each.value.rate_limit_options] : []
  #
  #     content {
  #       ban_duration_sec = rate_limit_options.value["ban_duration_sec"]
  #
  #       dynamic "ban_threshold" {
  #         for_each = rate_limit_options.value["ban_threshold"] != null ? [rate_limit_options.value["ban_threshold"]] : []
  #
  #         content {
  #           count        = ban_threshold.value["count"]
  #           interval_sec = ban_threshold.value["interval_sec"]
  #         }
  #       }
  #
  #       conform_action = rate_limit_options.value["conform_action"]
  #       enforce_on_key = rate_limit_options.value["enforce_on_key"]
  #
  #       dynamic "enforce_on_key_configs" {
  #         for_each = rate_limit_options.value["enforce_on_key_configs"] != null ? [rate_limit_options.value["enforce_on_key_configs"]] : []
  #
  #         content {
  #           enforce_on_key_type = enforce_on_key_configs.value["enforce_on_key_type"]
  #           enforce_on_key_name = enforce_on_key_configs.value["enforce_on_key_name"]
  #         }
  #       }
  #
  #       enforce_on_key_name = rate_limit_options.value["enforce_on_key_name"]
  #       exceed_action       = rate_limit_options.value["exceed_action"]
  #
  #       dynamic "rate_limit_threshold" {
  #         for_each = rate_limit_options.value["rate_limit_threshold"] != null ? [rate_limit_options.value["rate_limit_threshold"]] : []
  #
  #         content {
  #           count        = rate_limit_threshold.value["count"]
  #           interval_sec = rate_limit_threshold.value["interval_sec"]
  #         }
  #       }
  #     }
  #   }
}

resource "google_compute_region_health_check" "default" {
  provider = google

  for_each = var.compute_region_health_checks

  name = coalesce(each.value.name, each.key)

  check_interval_sec = each.value.check_interval_sec
  description        = each.value.description

  dynamic "grpc_health_check" {
    for_each = each.value["grpc_health_check"] != null ? [each.value["grpc_health_check"]] : []

    content {
      port               = grpc_health_check.value["port"]
      port_name          = grpc_health_check.value["port_name"]
      port_specification = grpc_health_check.value["port_specification"]
      grpc_service_name  = grpc_health_check.value["grpc_service_name"]
    }
  }

  healthy_threshold = each.value.healthy_threshold

  dynamic "http_health_check" {
    for_each = each.value["http_health_check"] != null ? [each.value["http_health_check"]] : []

    content {
      host               = http_health_check.value["host"]
      port               = http_health_check.value["port"]
      port_name          = http_health_check.value["port_name"]
      port_specification = http_health_check.value["port_specification"]
      proxy_header       = http_health_check.value["proxy_header"]
      request_path       = http_health_check.value["request_path"]
      response           = http_health_check.value["response"]
    }
  }

  dynamic "https_health_check" {
    for_each = each.value["https_health_check"] != null ? [each.value["https_health_check"]] : []

    content {
      host               = https_health_check.value["host"]
      port               = https_health_check.value["port"]
      port_name          = https_health_check.value["port_name"]
      port_specification = https_health_check.value["port_specification"]
      proxy_header       = https_health_check.value["proxy_header"]
      request_path       = https_health_check.value["request_path"]
      response           = https_health_check.value["response"]
    }
  }

  dynamic "http2_health_check" {
    for_each = each.value["http2_health_check"] != null ? [each.value["http2_health_check"]] : []

    content {
      host               = http2_health_check.value["host"]
      port               = http2_health_check.value["port"]
      port_name          = http2_health_check.value["port_name"]
      port_specification = http2_health_check.value["port_specification"]
      proxy_header       = http2_health_check.value["proxy_header"]
      request_path       = http2_health_check.value["request_path"]
      response           = http2_health_check.value["response"]
    }
  }

  dynamic "log_config" {
    for_each = each.value["log_config"] != null ? [each.value["log_config"]] : []

    content {
      enable = log_config.value["enable"]
    }
  }

  region = each.value.region

  dynamic "ssl_health_check" {
    for_each = each.value["ssl_health_check"] != null ? [each.value["ssl_health_check"]] : []

    content {
      port               = ssl_health_check.value["port"]
      port_name          = ssl_health_check.value["port_name"]
      port_specification = ssl_health_check.value["port_specification"]
      proxy_header       = ssl_health_check.value["proxy_header"]
      request            = ssl_health_check.value["request"]
      response           = ssl_health_check.value["response"]
    }
  }

  dynamic "tcp_health_check" {
    for_each = each.value["tcp_health_check"] != null ? [each.value["tcp_health_check"]] : []

    content {
      port               = tcp_health_check.value["port"]
      port_name          = tcp_health_check.value["port_name"]
      port_specification = tcp_health_check.value["port_specification"]
      proxy_header       = tcp_health_check.value["proxy_header"]
      request            = tcp_health_check.value["request"]
      response           = tcp_health_check.value["response"]
    }
  }

  timeout_sec         = each.value.timeout_sec
  unhealthy_threshold = each.value.unhealthy_threshold
}

resource "google_compute_region_backend_service" "default" {
  provider = google-beta

  for_each = var.compute_region_backend_services

  name = coalesce(each.value.name, each.key)

  affinity_cookie_ttl_sec = each.value.affinity_cookie_ttl_sec

  dynamic "backend" {
    for_each = each.value["backend"] != null ? [each.value["backend"]] : []

    content {
      balancing_mode               = backend.value["balancing_mode"]
      capacity_scaler              = backend.value["capacity_scaler"]
      description                  = backend.value["description"]
      failover                     = backend.value["failover"]
      group                        = try(google_compute_instance_group.default[backend.value["group"]].id, backend.value["group"])
      max_connections              = backend.value["max_connections"]
      max_connections_per_endpoint = backend.value["max_connections_per_endpoint"]
      max_connections_per_instance = backend.value["max_connections_per_instance"]
      max_rate                     = backend.value["max_rate"]
      max_rate_per_endpoint        = backend.value["max_rate_per_endpoint"]
      max_rate_per_instance        = backend.value["max_rate_per_instance"]
      max_utilization              = backend.value["max_utilization"]
    }
  }

  dynamic "cdn_policy" {
    for_each = each.value["cdn_policy"] != null ? [each.value["cdn_policy"]] : []

    content {
      dynamic "cache_key_policy" {
        for_each = cdn_policy.value["cache_key_policy"] != null ? [cdn_policy.value["cache_key_policy"]] : []

        content {
          include_host           = cache_key_policy.value["include_host"]
          include_named_cookies  = cache_key_policy.value["include_named_cookies"]
          include_protocol       = cache_key_policy.value["include_protocol"]
          include_query_string   = cache_key_policy.value["include_query_string"]
          query_string_blacklist = cache_key_policy.value["query_string_blacklist"]
          query_string_whitelist = cache_key_policy.value["query_string_whitelist"]
        }
      }

      cache_mode       = cdn_policy.value["cache_mode"]
      client_ttl       = cdn_policy.value["client_ttl"]
      default_ttl      = cdn_policy.value["default_ttl"]
      max_ttl          = cdn_policy.value["max_ttl"]
      negative_caching = cdn_policy.value["negative_caching"]

      dynamic "negative_caching_policy" {
        for_each = cdn_policy.value["negative_caching_policy"] != null ? [cdn_policy.value["negative_caching_policy"]] : []

        content {
          code = negative_caching_policy.value["code"]
        }
      }

      serve_while_stale            = cdn_policy.value["serve_while_stale"]
      signed_url_cache_max_age_sec = cdn_policy.value["signed_url_cache_max_age_sec"]
    }
  }

  dynamic "circuit_breakers" {
    for_each = each.value["circuit_breakers"] != null ? [each.value["circuit_breakers"]] : []

    content {
      max_connections             = circuit_breakers.value["max_connections"]
      max_pending_requests        = circuit_breakers.value["max_pending_requests"]
      max_requests                = circuit_breakers.value["max_requests"]
      max_requests_per_connection = circuit_breakers.value["max_requests_per_connection"]
      max_retries                 = circuit_breakers.value["max_retries"]
    }
  }

  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec

  dynamic "consistent_hash" {
    for_each = each.value["consistent_hash"] != null ? [each.value["consistent_hash"]] : []

    content {

      dynamic "http_cookie" {
        for_each = consistent_hash.value["http_cookie"] != null ? [consistent_hash.value["http_cookie"]] : []

        content {
          name = http_cookie.value["name"]
          path = http_cookie.value["path"]

          dynamic "ttl" {
            for_each = http_cookie.value["ttl"] != null ? [http_cookie.value["ttl"]] : []

            content {
              seconds = ttl.value["seconds"]
              nanos   = ttl.value["nanos"]
            }
          }
        }
      }

      http_header_name  = consistent_hash.value["http_header_name"]
      minimum_ring_size = consistent_hash.value["minimum_ring_size"]
    }
  }

  description = each.value.description
  enable_cdn  = each.value.enable_cdn

  dynamic "failover_policy" {
    for_each = each.value["failover_policy"] != null ? [each.value["failover_policy"]] : []

    content {
      disable_connection_drain_on_failover = failover_policy.value["disable_connection_drain_on_failover"]
      drop_traffic_if_unhealthy            = failover_policy.value["drop_traffic_if_unhealthy"]
      failover_ratio                       = failover_policy.value["failover_ratio"]
    }
  }

  health_checks = each.value.health_checks != null ? [
    for health_check in each.value.health_checks :
    try(google_compute_region_health_check.default[health_check].id, health_check)
  ] : null

  dynamic "iap" {
    for_each = each.value["iap"] != null ? [each.value["iap"]] : []

    content {
      enabled                     = iap.value["enabled"]
      oauth2_client_id            = iap.value["oauth2_client_id"]
      oauth2_client_secret        = iap.value["oauth2_client_secret"]
      oauth2_client_secret_sha256 = iap.value["oauth2_client_secret_sha256"]
    }
  }

  load_balancing_scheme = each.value.load_balancing_scheme
  locality_lb_policy    = each.value.locality_lb_policy

  dynamic "log_config" {
    for_each = each.value["log_config"] != null ? [each.value["log_config"]] : []

    content {
      enable      = log_config.value["enable"]
      sample_rate = log_config.value["sample_rate"]
    }
  }

  network = each.value.network

  dynamic "outlier_detection" {
    for_each = each.value["outlier_detection"] != null ? [each.value["outlier_detection"]] : []

    content {
      dynamic "base_ejection_time" {
        for_each = outlier_detection.value["base_ejection_time"] != null ? [outlier_detection.value["base_ejection_time"]] : []

        content {
          seconds = base_ejection_time.value["seconds"]
          nanos   = base_ejection_time.value["nanos"]
        }
      }

      consecutive_errors                    = outlier_detection.value["consecutive_errors"]
      consecutive_gateway_failure           = outlier_detection.value["consecutive_gateway_failure"]
      enforcing_consecutive_errors          = outlier_detection.value["enforcing_consecutive_errors"]
      enforcing_consecutive_gateway_failure = outlier_detection.value["enforcing_consecutive_gateway_failure"]
      enforcing_success_rate                = outlier_detection.value["enforcing_success_rate"]

      dynamic "interval" {
        for_each = outlier_detection.value["interval"] != null ? [outlier_detection.value["interval"]] : []

        content {
          seconds = interval.value["seconds"]
          nanos   = interval.value["nanos"]
        }
      }

      max_ejection_percent        = outlier_detection.value["max_ejection_percent"]
      success_rate_minimum_hosts  = outlier_detection.value["success_rate_minimum_hosts"]
      success_rate_request_volume = outlier_detection.value["success_rate_request_volume"]
      success_rate_stdev_factor   = outlier_detection.value["success_rate_stdev_factor"]
    }
  }

  port_name = each.value.port_name
  protocol  = each.value.protocol
  region    = each.value.region

  security_policy = try(google_compute_region_security_policy.default[each.value.security_policy].id, each.value.security_policy)

  session_affinity = each.value.session_affinity
  timeout_sec      = each.value.timeout_sec
}

resource "google_compute_address" "default" {
  provider = google

  for_each = var.compute_addresses

  name = coalesce(each.value.name, each.key)

  address            = each.value.address
  address_type       = each.value.address_type
  description        = each.value.description
  ipv6_endpoint_type = each.value.ipv6_endpoint_type
  ip_version         = each.value.ip_version
  network            = each.value.network
  network_tier       = each.value.network_tier
  prefix_length      = each.value.prefix_length
  purpose            = each.value.purpose
  region             = each.value.region
  subnetwork         = each.value.subnetwork
}

resource "google_compute_region_url_map" "default" {
  provider = google

  for_each = var.compute_region_url_maps

  name = coalesce(each.value.name, each.key)

  dynamic "default_route_action" {
    for_each = each.value["default_route_action"] != null ? [each.value["default_route_action"]] : []

    content {
      dynamic "cors_policy" {
        for_each = default_route_action.value["cors_policy"] != null ? [default_route_action.value["cors_policy"]] : []

        content {
          allow_credentials    = cors_policy.value["allow_credentials"]
          allow_headers        = cors_policy.value["allow_headers"]
          allow_methods        = cors_policy.value["allow_methods"]
          allow_origins        = cors_policy.value["allow_origins"]
          allow_origin_regexes = cors_policy.value["allow_origin_regexes"]
          disabled             = cors_policy.value["disabled"]
          expose_headers       = cors_policy.value["expose_headers"]
          max_age              = cors_policy.value["max_age"]
        }
      }

      dynamic "fault_injection_policy" {
        for_each = default_route_action.value["fault_injection_policy"] != null ? [default_route_action.value["fault_injection_policy"]] : []

        content {
          dynamic "abort" {
            for_each = fault_injection_policy.value["abort"] != null ? [fault_injection_policy.value["abort"]] : []

            content {
              http_status = abort.value["http_status"]
              percentage  = abort.value["percentage"]
            }
          }

          dynamic "delay" {
            for_each = fault_injection_policy.value["delay"] != null ? [fault_injection_policy.value["delay"]] : []

            content {
              dynamic "fixed_delay" {
                for_each = delay.value["fixed_delay"] != null ? [delay.value["fixed_delay"]] : []

                content {
                  nanos   = fixed_delay.value["nanos"]
                  seconds = fixed_delay.value["seconds"]
                }
              }

              percentage = delay.value["percentage"]
            }
          }
        }
      }

      dynamic "request_mirror_policy" {
        for_each = default_route_action.value["request_mirror_policy"] != null ? [default_route_action.value["request_mirror_policy"]] : []

        content {
          backend_service = request_mirror_policy.value["backend_service"]
        }
      }

      dynamic "retry_policy" {
        for_each = default_route_action.value["retry_policy"] != null ? [default_route_action.value["retry_policy"]] : []

        content {
          num_retries = retry_policy.value["num_retries"]

          dynamic "per_try_timeout" {
            for_each = retry_policy.value["per_try_timeout"] != null ? [retry_policy.value["per_try_timeout"]] : []

            content {
              nanos   = per_try_timeout.value["nanos"]
              seconds = per_try_timeout.value["seconds"]
            }
          }

          retry_conditions = retry_policy.value["retry_conditions"]
        }
      }

      dynamic "timeout" {
        for_each = default_route_action.value["timeout"] != null ? [default_route_action.value["timeout"]] : []

        content {
          nanos   = timeout.value["nanos"]
          seconds = timeout.value["seconds"]
        }
      }

      dynamic "url_rewrite" {
        for_each = default_route_action.value["url_rewrite"] != null ? [default_route_action.value["url_rewrite"]] : []

        content {
          host_rewrite        = url_rewrite.value["host_rewrite"]
          path_prefix_rewrite = url_rewrite.value["path_prefix_rewrite"]
        }
      }

      dynamic "weighted_backend_services" {
        for_each = default_route_action.value["weighted_backend_services"] != null ? default_route_action.value["weighted_backend_services"] : []

        content {
          backend_service = weighted_backend_services.value["backend_service"]

          dynamic "header_action" {
            for_each = weighted_backend_services.value["header_action"] != null ? weighted_backend_services.value["header_action"] : []

            content {
              dynamic "request_headers_to_add" {
                for_each = header_action.value["request_headers_to_add"] != null ? header_action.value["request_headers_to_add"] : []

                content {
                  header_name  = request_headers_to_add.value["header_name"]
                  header_value = request_headers_to_add.value["header_value"]
                  replace      = request_headers_to_add.value["replace"]
                }
              }

              request_headers_to_remove = header_action.value["request_headers_to_remove"]

              dynamic "response_headers_to_add" {
                for_each = header_action.value["response_headers_to_add"] != null ? header_action.value["response_headers_to_add"] : []

                content {
                  header_name  = response_headers_to_add.value["header_name"]
                  header_value = response_headers_to_add.value["header_value"]
                  replace      = response_headers_to_add.value["replace"]
                }
              }

              response_headers_to_remove = header_action.value["response_headers_to_remove"]
            }
          }

          weight = weighted_backend_services.value["weight"]
        }
      }
    }
  }

  default_service = try(google_compute_region_backend_service.default[each.value.default_service].id, each.value.default_service)

  dynamic "default_url_redirect" {
    for_each = each.value["default_url_redirect"] != null ? [each.value["default_url_redirect"]] : []

    content {
      strip_query            = default_url_redirect.value["strip_query"]
      host_redirect          = default_url_redirect.value["host_redirect"]
      https_redirect         = default_url_redirect.value["https_redirect"]
      path_redirect          = default_url_redirect.value["path_redirect"]
      prefix_redirect        = default_url_redirect.value["prefix_redirect"]
      redirect_response_code = default_url_redirect.value["redirect_response_code"]
    }
  }

  description = each.value.description

  dynamic "host_rule" {
    for_each = each.value["host_rule"] != null ? [each.value["host_rule"]] : []

    content {
      hosts        = host_rule.value["hosts"]
      path_matcher = host_rule.value["path_matcher"]
      description  = host_rule.value["description"]
    }
  }

  dynamic "path_matcher" {
    for_each = each.value["path_matcher"] != null ? [each.value["path_matcher"]] : []

    content {
      name            = path_matcher.value["name"]
      default_service = path_matcher.value["default_service"]

      dynamic "default_url_redirect" {
        for_each = path_matcher.value["default_url_redirect"] != null ? [path_matcher.value["default_url_redirect"]] : []

        content {
          strip_query            = default_url_redirect.value["strip_query"]
          host_redirect          = default_url_redirect.value["host_redirect"]
          https_redirect         = default_url_redirect.value["https_redirect"]
          path_redirect          = default_url_redirect.value["path_redirect"]
          prefix_redirect        = default_url_redirect.value["prefix_redirect"]
          redirect_response_code = default_url_redirect.value["redirect_response_code"]
        }
      }

      description = path_matcher.value["description"]

      dynamic "route_rules" {
        for_each = path_matcher.value["route_rules"] != null ? path_matcher.value["route_rules"] : []

        content {
          priority = route_rules.value["priority"]

          dynamic "header_action" {
            for_each = route_rules.value["header_action"] != null ? [route_rules.value["header_action"]] : []

            content {
              dynamic "request_headers_to_add" {
                for_each = header_action.value["request_headers_to_add"] != null ? [header_action.value["request_headers_to_add"]] : []

                content {
                  header_name  = request_headers_to_add.value["header_name"]
                  header_value = request_headers_to_add.value["header_value"]
                  replace      = request_headers_to_add.value["replace"]
                }
              }

              request_headers_to_remove = header_action.value["request_headers_to_remove"]

              dynamic "response_headers_to_add" {
                for_each = header_action.value["response_headers_to_add"] != null ? [header_action.value["response_headers_to_add"]] : []

                content {
                  header_name  = response_headers_to_add.value["header_name"]
                  header_value = response_headers_to_add.value["header_value"]
                  replace      = response_headers_to_add.value["replace"]
                }
              }

              response_headers_to_remove = header_action.value["response_headers_to_remove"]
            }
          }

          dynamic "match_rules" {
            for_each = route_rules.value["match_rules"] != null ? [route_rules.value["match_rules"]] : []

            content {
              full_path_match = match_rules.value["full_path_match"]

              dynamic "header_matches" {
                for_each = match_rules.value["header_matches"] != null ? match_rules.value["header_matches"] : []

                content {
                  header_name   = header_matches.value["header_name"]
                  exact_match   = header_matches.value["exact_match"]
                  invert_match  = header_matches.value["invert_match"]
                  prefix_match  = header_matches.value["prefix_match"]
                  present_match = header_matches.value["present_match"]

                  dynamic "range_match" {
                    for_each = header_matches.value["range_match"] != null ? [header_matches.value["range_match"]] : []

                    content {
                      range_end   = range_match.value["range_end"]
                      range_start = range_match.value["range_start"]
                    }
                  }

                  regex_match  = header_matches.value["regex_match"]
                  suffix_match = header_matches.value["suffix_match"]
                }
              }

              ignore_case = match_rules.value["ignore_case"]

              dynamic "metadata_filters" {
                for_each = match_rules.value["metadata_filters"] != null ? [match_rules.value["metadata_filters"]] : []

                content {
                  dynamic "filter_labels" {
                    for_each = metadata_filters.value["filter_labels"]

                    content {
                      name  = filter_labels.value["name"]
                      value = filter_labels.value["value"]
                    }
                  }

                  filter_match_criteria = metadata_filters.value["filter_match_criteria"]
                }
              }

              path_template_match = match_rules.value["path_template_match"]
              prefix_match        = match_rules.value["prefix_match"]

              dynamic "query_parameter_matches" {
                for_each = match_rules.value["query_parameter_matches"] != null ? match_rules.value["query_parameter_matches"] : []

                content {
                  name          = match_rules.value["name"]
                  exact_match   = match_rules.value["exact_match"]
                  present_match = match_rules.value["present_match"]
                  regex_match   = match_rules.value["regex_match"]
                }
              }

              regex_match = match_rules.value["regex_match"]
            }
          }

          dynamic "route_action" {
            for_each = route_rules.value["route_action"] != null ? [route_rules.value["route_action"]] : []

            content {
              dynamic "cors_policy" {
                for_each = route_action.value["cors_policy"] != null ? [route_action.value["cors_policy"]] : []

                content {
                  allow_credentials    = cors_policy.value["allow_credentials"]
                  allow_headers        = cors_policy.value["allow_headers"]
                  allow_methods        = cors_policy.value["allow_methods"]
                  allow_origins        = cors_policy.value["allow_origins"]
                  allow_origin_regexes = cors_policy.value["allow_origin_regexes"]
                  disabled             = cors_policy.value["disabled"]
                  expose_headers       = cors_policy.value["expose_headers"]
                  max_age              = cors_policy.value["max_age"]
                }
              }

              dynamic "fault_injection_policy" {
                for_each = route_action.value["fault_injection_policy"] != null ? [route_action.value["fault_injection_policy"]] : []

                content {
                  dynamic "abort" {
                    for_each = fault_injection_policy.value["abort"] != null ? [fault_injection_policy.value["abort"]] : []

                    content {
                      http_status = abort.value["http_status"]
                      percentage  = abort.value["percentage"]
                    }
                  }

                  dynamic "delay" {
                    for_each = fault_injection_policy.value["delay"] != null ? [fault_injection_policy.value["delay"]] : []

                    content {
                      dynamic "fixed_delay" {
                        for_each = delay.value["fixed_delay"] != null ? [delay.value["fixed_delay"]] : []

                        content {
                          seconds = fixed_delay.value["seconds"]
                          nanos   = fixed_delay.value["nanos"]
                        }
                      }

                      percentage = delay.value["percentage"]
                    }
                  }
                }
              }

              dynamic "request_mirror_policy" {
                for_each = route_action.value["request_mirror_policy"] != null ? [route_action.value["request_mirror_policy"]] : []

                content {
                  backend_service = request_mirror_policy.value["backend_service"]
                }
              }

              dynamic "retry_policy" {
                for_each = route_action.value["retry_policy"] != null ? [route_action.value["retry_policy"]] : []

                content {
                  num_retries = retry_policy.value["num_retries"]

                  dynamic "per_try_timeout" {
                    for_each = retry_policy.value["per_try_timeout"] != null ? [retry_policy.value["per_try_timeout"]] : []

                    content {
                      seconds = per_try_timeout.value["seconds"]
                      nanos   = per_try_timeout.value["nanos"]
                    }
                  }

                  retry_conditions = retry_policy.value["retry_conditions"]
                }
              }

              dynamic "timeout" {
                for_each = route_action.value["timeout"] != null ? [route_action.value["timeout"]] : []

                content {
                  seconds = timeout.value["seconds"]
                  nanos   = timeout.value["nanos"]
                }
              }

              dynamic "url_rewrite" {
                for_each = route_action.value["url_rewrite"] != null ? [route_action.value["url_rewrite"]] : []

                content {
                  host_rewrite          = url_rewrite.value["host_rewrite"]
                  path_prefix_rewrite   = url_rewrite.value["path_prefix_rewrite"]
                  path_template_rewrite = url_rewrite.value["path_template_rewrite"]
                }
              }

              dynamic "weighted_backend_services" {
                for_each = route_action.value["weighted_backend_services"] != null ? route_action.value["weighted_backend_services"] : []

                content {
                  backend_service = weighted_backend_services.value["backend_service"]
                  weight          = weighted_backend_services.value["weight"]

                  dynamic "header_action" {
                    for_each = weighted_backend_services.value["header_action"] != null ? [weighted_backend_services.value["header_action"]] : []

                    content {
                      dynamic "request_headers_to_add" {
                        for_each = header_action.value["request_headers_to_add"] != null ? [header_action.value["request_headers_to_add"]] : []

                        content {
                          header_name  = request_headers_to_add.value["header_name"]
                          header_value = request_headers_to_add.value["header_value"]
                          replace      = request_headers_to_add.value["replace"]
                        }
                      }

                      request_headers_to_remove = header_action.value["request_headers_to_remove"]

                      dynamic "response_headers_to_add" {
                        for_each = header_action.value["response_headers_to_add"] != null ? [header_action.value["response_headers_to_add"]] : []

                        content {
                          header_name  = response_headers_to_add.value["header_name"]
                          header_value = response_headers_to_add.value["header_value"]
                          replace      = response_headers_to_add.value["replace"]
                        }
                      }

                      response_headers_to_remove = header_action.value["response_headers_to_remove"]
                    }
                  }
                }
              }
            }
          }

          service = route_rules.value["service"]

          dynamic "url_redirect" {
            for_each = route_rules.value["url_redirect"] != null ? [route_rules.value["url_redirect"]] : []

            content {
              host_redirect          = url_redirect.value["host_redirect"]
              https_redirect         = url_redirect.value["https_redirect"]
              path_redirect          = url_redirect.value["path_redirect"]
              prefix_redirect        = url_redirect.value["prefix_redirect"]
              redirect_response_code = url_redirect.value["redirect_response_code"]
              strip_query            = url_redirect.value["strip_query"]
            }
          }
        }
      }

      dynamic "path_rule" {
        for_each = path_matcher.value["path_rule"] != null ? path_matcher.value["path_rule"] : []

        content {
          paths = path_rule.value["paths"]

          dynamic "route_action" {
            for_each = path_rule.value["route_action"] != null ? [path_rule.value["route_action"]] : []

            content {
              dynamic "cors_policy" {
                for_each = route_action.value["cors_policy"] != null ? [route_action.value["cors_policy"]] : []

                content {
                  allow_credentials    = cors_policy.value["allow_credentials"]
                  allow_headers        = cors_policy.value["allow_headers"]
                  allow_methods        = cors_policy.value["allow_methods"]
                  allow_origins        = cors_policy.value["allow_origins"]
                  allow_origin_regexes = cors_policy.value["allow_origin_regexes"]
                  disabled             = cors_policy.value["disabled"]
                  expose_headers       = cors_policy.value["expose_headers"]
                  max_age              = cors_policy.value["max_age"]
                }
              }

              dynamic "fault_injection_policy" {
                for_each = route_action.value["fault_injection_policy"] != null ? [route_action.value["fault_injection_policy"]] : []

                content {
                  dynamic "abort" {
                    for_each = fault_injection_policy.value["abort"] != null ? [fault_injection_policy.value["abort"]] : []

                    content {
                      http_status = abort.value["http_status"]
                      percentage  = abort.value["percentage"]
                    }
                  }

                  dynamic "delay" {
                    for_each = fault_injection_policy.value["delay"] != null ? [fault_injection_policy.value["delay"]] : []

                    content {
                      dynamic "fixed_delay" {
                        for_each = delay.value["fixed_delay"] != null ? [delay.value["fixed_delay"]] : []

                        content {
                          seconds = fixed_delay.value["seconds"]
                          nanos   = fixed_delay.value["nanos"]
                        }
                      }

                      percentage = delay.value["percentage"]
                    }
                  }
                }
              }

              dynamic "request_mirror_policy" {
                for_each = route_action.value["request_mirror_policy"] != null ? [route_action.value["request_mirror_policy"]] : []

                content {
                  backend_service = request_mirror_policy.value["backend_service"]
                }
              }

              dynamic "retry_policy" {
                for_each = route_action.value["retry_policy"] != null ? [route_action.value["retry_policy"]] : []

                content {
                  num_retries = retry_policy.value["num_retries"]

                  dynamic "per_try_timeout" {
                    for_each = retry_policy.value["per_try_timeout"] != null ? [retry_policy.value["per_try_timeout"]] : []

                    content {
                      seconds = per_try_timeout.value["seconds"]
                      nanos   = per_try_timeout.value["nanos"]
                    }
                  }

                  retry_conditions = retry_policy.value["retry_conditions"]
                }
              }

              dynamic "timeout" {
                for_each = route_action.value["timeout"] != null ? [route_action.value["timeout"]] : []

                content {
                  seconds = timeout.value["seconds"]
                  nanos   = timeout.value["nanos"]
                }
              }

              dynamic "url_rewrite" {
                for_each = route_action.value["url_rewrite"] != null ? [route_action.value["url_rewrite"]] : []

                content {
                  host_rewrite        = url_rewrite.value["host_rewrite"]
                  path_prefix_rewrite = url_rewrite.value["path_prefix_rewrite"]
                }
              }

              dynamic "weighted_backend_services" {
                for_each = route_action.value["weighted_backend_services"] != null ? route_action.value["weighted_backend_services"] : []

                content {
                  backend_service = weighted_backend_services.value["backend_service"]
                  weight          = weighted_backend_services.value["weight"]

                  dynamic "header_action" {
                    for_each = weighted_backend_services.value["header_action"] != null ? weighted_backend_services.value["header_action"] : []

                    content {
                      dynamic "request_headers_to_add" {
                        for_each = header_action.value["request_headers_to_add"] != null ? header_action.value["request_headers_to_add"] : []

                        content {
                          header_name  = request_headers_to_add.value["header_name"]
                          header_value = request_headers_to_add.value["header_value"]
                          replace      = request_headers_to_add.value["replace"]
                        }
                      }

                      request_headers_to_remove = header_action.value["request_headers_to_remove"]

                      dynamic "response_headers_to_add" {
                        for_each = header_action.value["response_headers_to_add"] != null ? header_action.value["response_headers_to_add"] : []

                        content {
                          header_name  = response_headers_to_add.value["header_name"]
                          header_value = response_headers_to_add.value["header_value"]
                          replace      = response_headers_to_add.value["replace"]
                        }
                      }

                      response_headers_to_remove = header_action.value["response_headers_to_remove"]
                    }
                  }
                }
              }
            }
          }

          service = path_rule.value["service"]

          dynamic "url_redirect" {
            for_each = path_rule.value["url_redirect"] != null ? [path_rule.value["url_redirect"]] : []

            content {
              strip_query            = url_redirect.value["strip_query"]
              host_redirect          = url_redirect.value["host_redirect"]
              https_redirect         = url_redirect.value["https_redirect"]
              path_redirect          = url_redirect.value["path_redirect"]
              prefix_redirect        = url_redirect.value["prefix_redirect"]
              redirect_response_code = url_redirect.value["redirect_response_code"]
            }
          }
        }
      }
    }
  }

  region = each.value.region

  dynamic "test" {
    for_each = each.value["test"] != null ? [each.value["test"]] : []

    content {
      host        = test.value["host"]
      path        = test.value["path"]
      service     = test.value["service"]
      description = test.value["description"]
    }
  }
}

resource "google_compute_region_target_http_proxy" "default" {
  provider = google

  for_each = var.compute_region_target_http_proxies

  name = coalesce(each.value.name, each.key)

  url_map = try(google_compute_region_url_map.default[each.value.url_map].id, each.value.url_map)

  description = each.value.description
  region      = each.value.region
}

resource "google_compute_forwarding_rule" "default" {
  provider = google

  for_each = var.compute_forwarding_rules

  name = coalesce(each.value.name, each.key)

  allow_global_access     = each.value.allow_global_access
  allow_psc_global_access = each.value.allow_psc_global_access
  all_ports               = each.value.all_ports
  backend_service         = each.value.backend_service
  description             = each.value.description
  ip_address              = try(google_compute_address.default[each.value.target].id, each.value.target)
  is_mirroring_collector  = each.value.is_mirroring_collector
  ip_protocol             = each.value.ip_protocol
  ip_version              = each.value.ip_version
  load_balancing_scheme   = each.value.load_balancing_scheme
  network                 = each.value.network
  network_tier            = each.value.network_tier
  no_automate_dns_zone    = each.value.no_automate_dns_zone
  port_range              = each.value.port_range
  ports                   = each.value.ports
  recreate_closed_psc     = each.value.recreate_closed_psc
  region                  = each.value.region

  dynamic "service_directory_registrations" {
    for_each = each.value["service_directory_registrations"] != null ? [each.value["service_directory_registrations"]] : []

    content {
      namespace = service_directory_registrations.value["namespace"]
      service   = service_directory_registrations.value["service"]
    }
  }

  service_label    = each.value.service_label
  source_ip_ranges = each.value.source_ip_ranges
  subnetwork       = each.value.subnetwork
  target           = try(google_compute_region_target_http_proxy.default[each.value.target].id, each.value.target)
}

