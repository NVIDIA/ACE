module "networking" {
  source = "../modules/gcp/networking/examples/quickstart-regional"
  name   = local.name
  region = local.region
}

module "firewall" {
  source         = "../modules/gcp/firewall"
  firewall_rules = local.firewall_rules
}

module "bastion" {
  count             = local.private_cluster_exists ? 1 : 0
  source            = "../modules/gcp/compute"
  compute_addresses = local.bastion.compute_addresses
  instance          = local.bastion.instance
}

module "master" {
  for_each          = local.masters
  source            = "../modules/gcp/compute"
  compute_addresses = each.value.compute_addresses
  instance          = each.value.instance
}

module "node" {
  for_each          = local.nodes
  source            = "../modules/gcp/compute"
  compute_addresses = each.value.compute_addresses
  instance          = each.value.instance
}

# module "load_balancer" {
#   for_each                             = local.load_balancers
#   source                               = "../modules/gcp/load-balancer"
#   compute_instance_groups              = each.value.compute_instance_groups
#   compute_region_security_policies     = each.value.compute_region_security_policies
#   compute_region_security_policy_rules = each.value.compute_region_security_policy_rules
#   compute_region_health_checks         = each.value.compute_region_health_checks
#   compute_region_backend_services      = each.value.compute_region_backend_services
#   compute_addresses                    = each.value.compute_addresses
#   compute_region_url_maps              = each.value.compute_region_url_maps
#   compute_region_target_http_proxies   = each.value.compute_region_target_http_proxies
#   compute_forwarding_rules             = each.value.compute_forwarding_rules
# }

module "api_instance_group" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-instance-group", local.name, k)
      } if v.private_instance
    }
  source              = "../modules/gcp/instance-group-unmanaged"
  name                = each.value.name
  zone                = module.master[each.key].instance.zone #one(distinct([for instance_suffix in var.instance_suffixes : module.api_instance[instance_suffix].zone]))
  instance_self_links = [module.master[each.key].instance.self_link]
  named_ports         = [
      {
        name = "api-port"
        port = 30888
      },
      {
        name = "ops-port"
        port = 31080
      }
    ]
}


module "api_backend" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-backend", local.name, k)
      } if v.private_instance
    }
  source                = "../modules/gcp/compute-backend-service"
  name                  = each.value.name
  port_name             = local.api_backend_config.port_name
  locality_lb_policy    = local.api_backend_config.locality_lb_policy
  load_balancing_scheme = local.api_backend_config.load_balancing_scheme
  group                 = module.api_instance_group[each.key].id
  access_policy         = local.api_backend_config.access_policy
  http_health_checks    = local.api_backend_config.http_health_checks
}


module "ops_backend" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-ops-backend", local.name, k)
      } if v.private_instance
    }
  source                = "../modules/gcp/compute-backend-service"
  name                  = each.value.name
  port_name             = local.ops_backend_config.port_name
  locality_lb_policy    = local.ops_backend_config.locality_lb_policy
  load_balancing_scheme = local.ops_backend_config.load_balancing_scheme
  group                 = module.api_instance_group[each.key].id
  access_policy         = local.ops_backend_config.access_policy
  http_health_checks    = local.ops_backend_config.http_health_checks
}

module "api_load_balancer" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-lb", local.name, k)
      } if v.private_instance
    }
  source           = "../modules/gcp/global-load-balancer"
  name             = each.value.name
  default_service  = module.api_backend[each.key].id
  ssl_certificates = [google_compute_managed_ssl_certificate.certificate.id]
  https_port_range = local.api_lb_config.https_port_range
  http_port_range  = local.api_lb_config.http_port_range
  host_rules       = local.api_lb_config.host_rules
  path_matchers    = local.api_lb_config.path_matchers
  service          = module.ops_backend[each.key].id
}