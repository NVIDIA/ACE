
resource "google_compute_security_policy" "this" {
  count = var.access_policy == null ? 0 : 1
  name  = format("%s-access", var.name)
  dynamic "rule" {
    for_each = var.access_policy.rules
    content {
      action   = rule.value["action"]
      preview  = rule.value["preview"]
      priority = rule.value["priority"]
      dynamic "match" {
        for_each = rule.value["matches"]
        content {
          versioned_expr = match.value["versioned_expr"]
          dynamic "config" {
            for_each = match.value["configs"]
            content {
              src_ip_ranges = config.value["src_ip_ranges"]
            }
          }
        }
      }
    }
  }
}

resource "google_compute_health_check" "this" {
  name                = format("%s-health-check", var.name)
  healthy_threshold   = 2
  unhealthy_threshold = 5
  check_interval_sec  = 30
  timeout_sec         = 5
  dynamic "http_health_check" {
    for_each = var.http_health_checks
    content {
      request_path = http_health_check.value["request_path"]
      port         = http_health_check.value["port"]
    }
  }
}

resource "google_compute_backend_service" "this" {
  name                  = format("%s-backend", var.name)
  port_name             = var.port_name
  locality_lb_policy    = var.locality_lb_policy
  load_balancing_scheme = var.load_balancing_scheme
  security_policy       = one(google_compute_security_policy.this.*.id)
  health_checks         = [google_compute_health_check.this.id]
  backend {
    group           = var.group
    max_utilization = 0.8
  }
}