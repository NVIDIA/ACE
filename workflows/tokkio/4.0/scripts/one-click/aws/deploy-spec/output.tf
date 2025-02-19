
output "bastion_infra" {
  value = {
    public_ip  = module.base.bastion_instance.public_ip
    private_ip = module.base.bastion_instance.private_ip
  }
}

output "coturn_infra" {
  value = one(module.coturn) != null ? {
    public_ip  = nonsensitive(one(module.coturn)["public_ip"])
    private_ip = nonsensitive(one(module.coturn)["private_ip"])
    port       = nonsensitive(one(module.coturn)["port"])
  } : null
}

output "app_infra" {
  value = {
    private_ips            = module.app.private_ips
    api_endpoint           = module.app.api_endpoint
    ui_endpoint            = module.app.ui_endpoint
    elasticsearch_endpoint = module.app.elasticsearch_endpoint
    kibana_endpoint        = module.app.kibana_endpoint
    grafana_endpoint       = module.app.grafana_endpoint
  }
}

output "rp_infra" {
  value = one(module.rp)
}