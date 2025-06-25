output "instance_groups" {
  value       = google_compute_instance_group.default
  description = "The outputs of the instance groups."
}

output "region_security_policy" {
  value       = google_compute_region_security_policy.default
  description = "The outputs of the region security policies."
}

output "region_security_policy_rule" {
  value       = google_compute_region_security_policy_rule.default
  description = "The outputs of the region security policy rules."
}

output "region_health_checks" {
  value       = google_compute_region_health_check.default
  description = "The outputs of the region health checks."
}

output "region_backend_services" {
  value       = google_compute_region_backend_service.default
  description = "The outputs of the region backend services."
}

output "addresses" {
  value       = google_compute_address.default
  description = "The outputs of the addresses."
}

output "region_url_maps" {
  value       = google_compute_region_url_map.default
  description = "The outputs of the region url map."
}

output "region_target_http_proxies" {
  value       = google_compute_region_target_http_proxy.default
  description = "The outputs of the region target http proxies."
}

output "forwarding_rules" {
  value       = google_compute_forwarding_rule.default
  description = "The outputs of the forwarding rules."
}
