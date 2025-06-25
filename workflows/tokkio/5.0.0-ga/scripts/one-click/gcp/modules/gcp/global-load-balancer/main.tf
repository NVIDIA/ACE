
resource "google_compute_global_address" "this" {
  name = format("%s-lb-ip", var.name)
}

resource "google_compute_url_map" "https" {
  name            = format("%s-https", var.name)
  default_service = var.default_service
  dynamic "host_rule" {
    for_each = var.host_rules
    content {
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.value.path_matcher
    }
  }
  dynamic "path_matcher" {
    for_each = var.path_matchers
    content {
      name            = path_matcher.value.name
      default_service = coalesce(
                          lookup(path_matcher.value, "default_service", null),
                          var.service,
                          var.default_service
                        )
      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules
        content {
          paths   = path_rule.value.paths
          service = coalesce(
                    lookup(path_rule.value, "service", null),
                    var.service,
                    var.default_service
                  ) 
        }
      }
    }
  }
}

resource "google_compute_url_map" "http" {
  name = format("%s-http", var.name)
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_https_proxy" "this" {
  name             = format("%s-https", var.name)
  url_map          = google_compute_url_map.https.id
  ssl_certificates = var.ssl_certificates
}

resource "google_compute_target_http_proxy" "this" {
  name    = format("%s-http", var.name)
  url_map = google_compute_url_map.http.id
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = format("%s-https", var.name)
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = var.https_port_range
  target                = google_compute_target_https_proxy.this.id
  ip_address            = google_compute_global_address.this.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = format("%s-http", var.name)
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = var.http_port_range
  target                = google_compute_target_http_proxy.this.id
  ip_address            = google_compute_global_address.this.id
}