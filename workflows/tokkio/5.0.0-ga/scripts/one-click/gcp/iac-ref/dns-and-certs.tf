
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
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-lb", local.name, k)
      } if v.private_instance
    }
  name         = local.ui_domain_dns
  managed_zone = local.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [module.ui_load_balancer[each.key].ip_address]
}

resource "google_dns_record_set" "application_dns" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-lb", local.name, k)
      } if v.private_instance
    }
  name         = local.api_domain_dns
  managed_zone = local.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [module.api_load_balancer[each.key].ip_address]
}

resource "google_dns_record_set" "ace_configurator_dns" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-lb", local.name, k)
      } if v.private_instance
    }
  name         = local.ace_configurator_domain_dns
  managed_zone = local.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [module.api_load_balancer[each.key].ip_address]
} 


resource "google_dns_record_set" "grafana_dns" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-lb", local.name, k)
      } if v.private_instance
    }
  name         = local.grafana_domain_dns
  managed_zone = local.dns_zone_name
  type         = "A"
  ttl          = 60
  rrdatas      = [module.api_load_balancer[each.key].ip_address]
}