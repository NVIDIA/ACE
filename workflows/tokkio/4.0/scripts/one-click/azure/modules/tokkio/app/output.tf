
output "private_ips" {
  value = [for instance_suffix in var.instance_suffixes : module.api_vm[instance_suffix].private_ip]
}
output "ui_endpoint" {
  value = local.ui_endpoint
}
output "api_endpoint" {
  value = local.api_endpoint
}
output "elasticsearch_endpoint" {
  value = "https://${local.elastic_domain}"
}
output "kibana_endpoint" {
  value = "https://${local.kibana_domain}"
}
output "grafana_endpoint" {
  value = "https://${local.grafana_domain}"
}