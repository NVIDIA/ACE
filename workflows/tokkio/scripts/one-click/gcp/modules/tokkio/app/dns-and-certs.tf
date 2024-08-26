
data "google_dns_managed_zone" "dns_zone" {
  name = local.dns_zone_name
}

resource "google_compute_managed_ssl_certificate" "certificate" {
  name = local.certificate_config.name
  managed {
    domains = local.certificate_config.domains
  }
}

resource "google_dns_record_set" "ui_dns" {
  name         = local.ui_domain_dns
  managed_zone = local.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [module.ui_load_balancer.ip_address]
}

resource "google_dns_record_set" "application_dns" {
  name         = local.api_domain_dns
  managed_zone = local.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [module.api_load_balancer.ip_address]
}

resource "google_dns_record_set" "elastic_dns" {
  name         = local.elastic_domain_dns
  managed_zone = local.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [module.api_load_balancer.ip_address]
}

resource "google_dns_record_set" "kibana_dns" {
  name         = local.kibana_domain_dns
  managed_zone = local.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [module.api_load_balancer.ip_address]
}

resource "google_dns_record_set" "grafana_dns" {
  name         = local.grafana_domain_dns
  managed_zone = local.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [module.api_load_balancer.ip_address]
}