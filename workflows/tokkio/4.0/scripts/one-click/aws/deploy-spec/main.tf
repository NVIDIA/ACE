
module "base" {
  source                       = "../modules/tokkio/base"
  name                         = var.name
  cidr_block                   = var.vpc_cidr_block
  ssh_public_key               = var.ssh_public_key
  dev_access_ipv4_cidr_blocks  = var.dev_access_ipv4_cidr_blocks
  user_access_ipv4_cidr_blocks = var.user_access_ipv4_cidr_blocks
  base_domain                  = var.base_domain
  bastion_ami_name             = var.ami_name
  providers = {
    aws            = aws
    aws.cloudfront = aws.cloudfront
  }
}

module "coturn" {
  count           = lower(var.turn_server_provider) == "coturn" ? 1 : 0
  source          = "../modules/tokkio/coturn"
  name            = var.name
  base_config     = module.base
  coturn_settings = var.coturn_settings
  coturn_ami_name = var.ami_name
}
module "rp" {
  count                      = lower(var.turn_server_provider) == "rp" ? 1 : 0
  source                     = "../modules/tokkio/rp"
  name                       = var.name
  base_config                = module.base
  instance_suffixes          = ["1"]
  ngc_api_key                = var.ngc_api_key
  instance_type              = var.rp_instance_type
  instance_data_disk_size_gb = var.rp_instance_data_disk_size_gb
  rp_settings                = var.rp_settings
  rp_ami_name                = var.ami_name
}
module "app" {
  source                         = "../modules/tokkio/app"
  name                           = var.name
  base_config                    = module.base
  coturn_settings                = one(module.coturn)
  instance_suffixes              = ["1"]
  api_sub_domain                 = var.api_sub_domain
  ui_sub_domain                  = var.ui_sub_domain
  elastic_sub_domain             = var.elastic_sub_domain
  kibana_sub_domain              = var.kibana_sub_domain
  grafana_sub_domain             = var.grafana_sub_domain
  cdn_cache_enabled              = var.cdn_cache_enabled
  twilio_settings                = var.twilio_settings
  app_instance_type              = var.app_instance_type
  app_instance_data_disk_size_gb = var.app_instance_data_disk_size_gb
  app_ami_name                   = var.ami_name
  ops_settings                   = var.ops_settings
  api_settings                   = var.api_settings
  ui_settings                    = var.ui_settings
  rp_settings                    = one(module.rp)
  turn_server_provider           = var.turn_server_provider
  ngc_api_key                    = var.ngc_api_key
  providers = {
    aws            = aws
    aws.cloudfront = aws.cloudfront
  }
}
