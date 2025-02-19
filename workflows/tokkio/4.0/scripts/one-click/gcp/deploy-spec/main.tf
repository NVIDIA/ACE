
module "base" {
  source                 = "../modules/tokkio/base"
  name                   = var.name
  location               = var.location
  region                 = var.region
  ui_bucket_location     = var.ui_bucket_location
  zone                   = var.zone
  network_cidr_range     = var.network_cidr_range
  ssh_public_key         = var.ssh_public_key
  dev_access_cidrs       = var.dev_access_cidrs
  user_access_cidrs      = var.user_access_cidrs
  bastion_instance_image = var.instance_image
}

module "coturn" {
  count                 = lower(var.turn_server_provider) == "coturn" ? 1 : 0
  source                = "../modules/tokkio/coturn"
  name                  = var.name
  base_config           = module.base
  coturn_settings       = var.coturn_settings
  coturn_instance_image = var.instance_image
}

module "rp" {
  count                      = lower(var.turn_server_provider) == "rp" ? 1 : 0
  source                     = "../modules/tokkio/rp"
  name                       = var.name
  base_config                = module.base
  instance_suffixes          = ["1"]
  ngc_api_key                = var.ngc_api_key
  instance_machine_type      = var.rp_instance_machine_type
  instance_data_disk_size_gb = var.rp_instance_data_disk_size_gb
  rp_instance_image          = var.instance_image
  rp_settings                = var.rp_settings
}

module "app" {
  source                         = "../modules/tokkio/app"
  name                           = var.name
  base_config                    = module.base
  coturn_settings                = one(module.coturn)
  instance_suffixes              = ["1"]
  dns_zone_name                  = var.dns_zone_name
  api_sub_domain                 = var.api_sub_domain
  ui_sub_domain                  = var.ui_sub_domain
  elastic_sub_domain             = var.elastic_sub_domain
  kibana_sub_domain              = var.kibana_sub_domain
  grafana_sub_domain             = var.grafana_sub_domain
  enable_cdn                     = var.enable_cdn
  ngc_api_key                    = var.ngc_api_key
  api_instance_machine_type      = var.api_instance_machine_type
  api_instance_data_disk_size_gb = var.api_instance_data_disk_size_gb
  api_instance_image             = var.instance_image
  turn_server_provider           = var.turn_server_provider
  twilio_settings                = var.twilio_settings
  api_settings                   = var.api_settings
  ui_settings                    = var.ui_settings
  ops_settings                   = var.ops_settings
  rp_settings                    = one(module.rp)
}