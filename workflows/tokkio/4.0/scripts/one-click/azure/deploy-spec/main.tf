
module "base" {
  source                        = "../modules/tokkio/base"
  name                          = var.name
  region                        = var.region
  virtual_network_address_space = var.virtual_network_address_space
  ssh_public_key                = var.ssh_public_key
  dev_source_address_prefixes   = var.dev_source_address_prefixes
  user_source_address_prefixes  = var.user_source_address_prefixes
  dns_and_certs_configs         = var.dns_and_certs_configs
  bastion_vm_image_version      = var.vm_image_version
}

module "coturn" {
  count                   = lower(var.turn_server_provider) == "coturn" ? 1 : 0
  source                  = "../modules/tokkio/coturn"
  name                    = var.name
  base_config             = module.base
  turnserver_realm        = var.coturn_settings.realm
  turnserver_username     = var.coturn_settings.username
  turnserver_password     = var.coturn_settings.password
  coturn_vm_image_version = var.vm_image_version
}

module "app" {
  source                   = "../modules/tokkio/app"
  name                     = var.name
  instance_suffixes        = ["1"]
  base_config              = module.base
  coturn_settings          = one(module.coturn)
  twilio_settings          = var.twilio_settings
  rp_settings              = one(module.rp)
  api_settings             = var.api_settings
  ui_settings              = var.ui_settings
  turn_server_provider     = var.turn_server_provider
  ngc_api_key              = var.ngc_api_key
  api_sub_domain           = var.api_sub_domain
  include_ui_custom_domain = var.include_ui_custom_domain
  ui_sub_domain            = var.ui_sub_domain
  api_vm_size              = var.api_vm_size
  api_vm_data_disk_size_gb = var.api_vm_data_disk_size_gb
  api_vm_image_version     = var.vm_image_version
  elastic_sub_domain       = var.elastic_sub_domain
  kibana_sub_domain        = var.kibana_sub_domain
  grafana_sub_domain       = var.grafana_sub_domain
}

module "rp" {
  count                   = lower(var.turn_server_provider) == "rp" ? 1 : 0
  source                  = "../modules/tokkio/rp"
  name                    = var.name
  base_config             = module.base
  instance_suffixes       = ["1"]
  ngc_api_key             = var.ngc_api_key
  rp_vm_size              = var.rp_vm_size
  rp_vm_data_disk_size_gb = var.rp_vm_data_disk_size_gb
  rp_vm_image_version     = var.vm_image_version
  rp_settings             = var.rp_settings
}