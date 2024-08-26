
module "api_vm" {
  source                 = "../../azure/linux-virtual-machine"
  for_each               = toset(var.instance_suffixes)
  name                   = format("%s-%s", local.api_vm_name, each.key)
  resource_group_name    = var.base_config.resource_group.name
  region                 = var.base_config.networking.region
  subnet_id              = var.base_config.networking.api_vm_subnet_id
  include_public_ip      = false
  size                   = local.api_vm_details.size
  zone                   = local.api_vm_details.zone
  user_data              = local.api_vm_config_user_data
  admin_username         = local.api_vm_details.admin_username
  ssh_public_key         = var.base_config.keypair.public_key
  accelerated_networking = local.api_vm_details.accelerated_networking
  image_details          = local.api_vm_details.image_details
  os_disk_details        = local.api_vm_details.os_disk_details
  data_disk_details      = local.api_vm_details.data_disk_details
  identity               = local.api_vm_details.identity
}

module "api_app_gw" {
  source                     = "../../azure/application-gateway"
  name                       = local.api_app_gw_name
  resource_group_name        = var.base_config.resource_group.name
  region                     = var.base_config.networking.region
  backend_address_pools      = local.api_app_gw_settings.backend_address_pools
  backend_http_settings      = local.api_app_gw_settings.backend_http_settings
  frontend_ip_configurations = local.api_app_gw_settings.frontend_ip_configurations
  frontend_ports             = local.api_app_gw_settings.frontend_ports
  gateway_ip_configurations  = local.api_app_gw_settings.gateway_ip_configurations
  http_listeners             = local.api_app_gw_settings.http_listeners
  request_routing_rules      = local.api_app_gw_settings.request_routing_rules
  probes                     = local.api_app_gw_settings.probes
  ssl_certificates           = local.api_app_gw_settings.ssl_certificates
  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
  identity = {
    identity_ids = [azurerm_user_assigned_identity.certificate_reader.id]
    type         = "UserAssigned"
  }
}

module "api_dns" {
  source            = "../../azure/dns-a-record"
  name              = var.api_sub_domain
  base_domain       = local.base_domain
  ttl               = 3600
  azure_resource_id = null
  ip_addresses      = [module.api_app_gw.public_ip[local.api_app_gw_public_ip_name]]
}

module "ops_dns" {
  source            = "../../azure/dns-a-record"
  for_each          = toset([local.elastic_sub_domain, local.kibana_sub_domain, local.grafana_sub_domain])
  name              = each.key
  base_domain       = local.base_domain
  ttl               = 3600
  azure_resource_id = null
  ip_addresses      = [module.api_app_gw.public_ip[local.api_app_gw_public_ip_name]]
}