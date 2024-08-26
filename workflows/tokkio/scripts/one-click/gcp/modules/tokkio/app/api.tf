
module "api_instance" {
  source                    = "../../gcp/instance"
  for_each                  = toset(var.instance_suffixes)
  name                      = format("%s-%s", local.api_instance_config.name, each.value)
  region                    = local.api_instance_config.region
  zone                      = local.api_instance_config.zone
  network                   = local.api_instance_config.network
  subnetwork                = local.api_instance_config.subnetwork
  static_public_ip          = local.api_instance_config.static_public_ip
  network_interface         = local.api_instance_config.network_interface
  tags                      = local.api_instance_config.tags
  machine_type              = local.api_instance_config.machine_type
  service_account_email     = google_service_account.api_instance_service_account.email
  service_account_scopes    = local.api_instance_config.service_account_scopes
  boot_disk                 = local.api_instance_config.boot_disk
  data_disks                = local.api_instance_config.data_disks
  ssh_public_key            = local.api_instance_config.ssh_public_key
  ssh_user                  = local.api_instance_config.ssh_user
  metadata_startup_script   = local.api_instance_config.metadata_startup_script
  advanced_machine_features = local.api_instance_config.advanced_machine_features
  guest_accelerators        = local.api_instance_config.guest_accelerators
  schedulings               = local.api_instance_config.schedulings
  depends_on = [
    google_storage_bucket_iam_member.api_instance_config_viewer_access,
    google_storage_bucket_iam_member.api_instance_ui_bucket_write_access
  ]
}

module "api_instance_group" {
  source              = "../../gcp/instance-group-unmanaged"
  name                = local.api_instance_config.name
  zone                = one(distinct([for instance_suffix in var.instance_suffixes : module.api_instance[instance_suffix].zone]))
  instance_self_links = [for instance_suffix in var.instance_suffixes : module.api_instance[instance_suffix].self_link]
  named_ports         = local.api_instance_config.group_named_ports
}

module "api_backend" {
  source                = "../../gcp/compute-backend-service"
  name                  = local.api_backend_config.name
  port_name             = local.api_backend_config.port_name
  locality_lb_policy    = local.api_backend_config.locality_lb_policy
  load_balancing_scheme = local.api_backend_config.load_balancing_scheme
  group                 = module.api_instance_group.id
  access_policy         = local.api_backend_config.access_policy
  http_health_checks    = local.api_backend_config.http_health_checks
}


module "ops_backend" {
  source                = "../../gcp/compute-backend-service"
  name                  = local.ops_backend_config.name
  port_name             = local.ops_backend_config.port_name
  locality_lb_policy    = local.ops_backend_config.locality_lb_policy
  load_balancing_scheme = local.ops_backend_config.load_balancing_scheme
  group                 = module.api_instance_group.id
  access_policy         = local.ops_backend_config.access_policy
  http_health_checks    = local.ops_backend_config.http_health_checks
}


module "api_load_balancer" {
  source           = "../../gcp/global-load-balancer"
  name             = local.api_lb_config.name
  default_service  = module.api_backend.id
  ssl_certificates = [google_compute_managed_ssl_certificate.certificate.id]
  https_port_range = local.api_lb_config.https_port_range
  http_port_range  = local.api_lb_config.http_port_range
  host_rules       = local.ops_backend_config.host_rules
  path_matchers    = local.ops_backend_config.path_matchers
  service          = module.ops_backend.id
}

##ops_instance_group, ops_backend and load_balancer
# module "ops_instance_group" {  ##not needed because same instace cant be part of two different TG
#   source              = "../../gcp/instance-group-unmanaged"
#   name                = format("%s-ops", local.name)
#   zone                = one(distinct([for instance_suffix in var.instance_suffixes : module.api_instance[instance_suffix].zone]))
#   instance_self_links = [for instance_suffix in var.instance_suffixes : module.api_instance[instance_suffix].self_link]
#   named_ports         = [
#       {
#         name = "ops-port"
#         port = 30888
#       }
#     ]
# }

# resource "google_compute_url_map" "existing_api_map" {
#   name            = "tok-gsj1-ops-https"
#   default_service = module.ops_backend.id

#   host_rule {
#     hosts        = [local.elastic_domain, local.kibana_domain, local.grafana_domain]
#     path_matcher = "path-matcher-1"
#   }

#   path_matcher {
#     name            = "path-matcher-1"
#     default_service = module.ops_backend.id

#     path_rule {
#       paths   = ["/"]
#       service = module.ops_backend.id
#     }
#   }
# }
# resource "google_compute_url_map" "https" {
#   #id                 = "projects/nv-tokkiodev-20221021/global/urlMaps/tok-gsj1-api-https"
#   name               = module.api_load_balancer.self_link
#   default_service = "https://www.googleapis.com/compute/v1/projects/nv-tokkiodev-20221021/global/backendServices/tok-gsj1-api-backend"
#   host_rule {
#           hosts        = [
#             "tok-gsj1-elastic.tokkio-dev-gcp.nvidia.com",
#             "tok-gsj1-grafana.tokkio-dev-gcp.nvidia.com",
#             "tok-gsj1-kibana.tokkio-dev-gcp.nvidia.com",
#             ]
#           path_matcher = "path-matcher-1"
#         }
#   path_matcher {
#         default_service = "https://www.googleapis.com/compute/v1/projects/nv-tokkiodev-20221021/global/backendServices/tok-gsj1-api-backend"
#         name            = "path-matcher-1"
#         path_rule {
#             paths   = ["/"]
#             service = "https://www.googleapis.com/compute/v1/projects/nv-tokkiodev-20221021/global/backendServices/tok-gsj1-ops-backend"
#             }
#         }
#     }
