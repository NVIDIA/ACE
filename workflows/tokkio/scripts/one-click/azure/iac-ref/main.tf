module "resource_group" {
  source   = "../modules/azure/resource-group"
  name     = local.name
  location = local.location
}

module "networking" {
  source              = "../modules/azure/networking/examples/quickstart"
  name                = local.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  public_subnets      = [local.public_vm_subnet, local.app_gw_subnet]
  private_subnets     = [local.private_vm_subnet]
}

module "app_security_group" {
  source                      = "../modules/azure/app-security-group"
  application_security_groups = [] #compact(concat(local.private_cluster_exists ? [local.bastion_sg_name] : [], local.private_cluster_sg_names, local.public_cluster_sg_names))
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  network_security_rules      = local.network_security_rules
}

module "bastion" {
  count                          = local.private_cluster_exists ? 1 : 0
  source                         = "../modules/azure/compute"
  name                           = format("%s-bastion", local.name)
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = local.public_vm_subnet_id
  admin_username                 = local.bastion.admin_username
  attach_public_ip               = local.bastion.attach_public_ip
  image_offer                    = local.bastion.image_offer
  image_publisher                = local.bastion.image_publisher
  image_sku                      = local.bastion.image_sku
  image_version                  = local.bastion.image_version
  size                           = var.bastion.size
  ssh_public_key                 = var.ssh_public_key
  zone                           = var.bastion.zone
  os_disk_size_gb                = var.bastion.disk_size_gb
  #network_security_group_ids     = [for nsg in sort(keys(module.networking.network_security_group)) : module.networking.network_security_group[nsg] if nsg == "public"]
  #application_security_group_ids = [for asg in sort(keys(module.app_security_group.application_security_group)) : module.app_security_group.application_security_group[asg] if asg == local.bastion_sg_name]
  encryption_at_host_enabled     = var.encryption_at_host_enabled
}

module "master" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => merge(var.clusters[cluster].master, {
      private_instance   = var.clusters[cluster].private_instance
      cluster_visibility = var.clusters[cluster].private_instance ? "private" : "public"
      subnet_id          = var.clusters[cluster].private_instance ? local.private_vm_subnet_id : local.public_vm_subnet_id
    })
  }
  source                         = "../modules/azure/compute"
  name                           = format("%s-%s-master", local.name, each.key)
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = each.value["subnet_id"]
  admin_username                 = local.cluster.admin_username
  attach_public_ip               = !each.value["private_instance"]
  image_offer                    = local.cluster.image_offer
  image_publisher                = local.cluster.image_publisher
  image_sku                      = local.cluster.image_sku
  image_version                  = local.cluster.image_version
  size                           = each.value["size"]
  ssh_public_key                 = var.ssh_public_key
  zone                           = each.value["zone"]
  os_disk_size_gb                = each.value["disk_size_gb"]
  #network_security_group_ids     = [for nsg in sort(keys(module.networking.network_security_group)) : module.networking.network_security_group[nsg] if nsg == each.value["cluster_visibility"]]
  #application_security_group_ids = [for asg in sort(keys(module.app_security_group.application_security_group)) : module.app_security_group.application_security_group[asg] if asg == format("%s-%s", local.name, each.key)]
  encryption_at_host_enabled     = var.encryption_at_host_enabled
  identity                       = each.value["private_instance"] ? local.identity : null
  data_disk_details      = each.value["data_disk_size_gb"] != null ? local.data_disk_details : [] 
}

module "node" {
  for_each = merge([for cluster in keys(var.clusters) : {
    for node in keys(var.clusters[cluster].nodes) :
    format("%s-%s", cluster, node) => merge(var.clusters[cluster].nodes[node], {
      cluster            = cluster
      private_instance   = var.clusters[cluster].private_instance
      cluster_visibility = var.clusters[cluster].private_instance ? "private" : "public"
      subnet_id          = var.clusters[cluster].private_instance ? local.private_vm_subnet_id : local.public_vm_subnet_id
    })
  }]...)
  source                         = "../modules/azure/compute"
  name                           = format("%s-%s", local.name, each.key)
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = each.value["subnet_id"]
  admin_username                 = local.cluster.admin_username
  attach_public_ip               = !each.value["private_instance"]
  image_offer                    = local.cluster.image_offer
  image_publisher                = local.cluster.image_publisher
  image_sku                      = local.cluster.image_sku
  image_version                  = local.cluster.image_version
  size                           = each.value["size"]
  ssh_public_key                 = var.ssh_public_key
  zone                           = each.value["zone"]
  os_disk_size_gb                = each.value["disk_size_gb"]
  network_security_group_ids     = [for nsg in sort(keys(module.networking.network_security_group)) : module.networking.network_security_group[nsg] if nsg == each.value["cluster_visibility"]]
  #application_security_group_ids = [for asg in sort(keys(module.app_security_group.application_security_group)) : module.app_security_group.application_security_group[asg] if asg == format("%s-%s", local.name, each.key)]
  encryption_at_host_enabled     = var.encryption_at_host_enabled
}

module "app_gateway" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => {
      name  = format("%s-%s-app-gw", local.name, cluster)
      ports = var.clusters[cluster].ports
    }
    if var.clusters[cluster].private_instance
  }
  source              = "../modules/azure/app-gateway"
  name                = each.value["name"]
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  backend_address_pools = [
    {
      name = each.value["name"]
      ip_addresses = concat(
        [module.master[each.key].private_ip],
        [for node in keys(var.clusters[each.key].nodes) : module.node[format("%s-%s", each.key, node)].private_ip]
      )
  }]
  probes = [
    for port in sort(keys(each.value["ports"])) : {
      name     = format("%s-%s-probe", each.value["name"], port)
      path     = format("/%s", trimprefix(each.value["ports"][port]["path"], "/"))
      protocol = title(each.value["ports"][port]["protocol"])
      host     = port == "ops" ?  local.elastic_domain : "127.0.0.1"
      match = {
        status_code = ["200-399"]
      }
      port = coalesce(each.value["ports"][port]["health_check_port"], each.value["ports"][port]["port"])
    }
  ]
  backend_http_settings = [
    for port in sort(keys(each.value["ports"])) : {
      name       = format("%s-%s-http-setting", each.value["name"], port)
      port       = each.value["ports"][port]["port"]
      protocol   = title(each.value["ports"][port]["protocol"])
      probe_name = format("%s-%s-probe", each.value["name"], port)
    }
  ]
  frontend_ip_configurations = [
    {
      name = each.value["name"]
      public_ip_address = {
        name = each.value["name"] #local.api_app_gw_public_ip_name
      }
    }
  ]
  # frontend_ports = [
  #   for port in sort(keys(each.value["ports"])) : {
  #     name = format("%s-%s-frontend-port", each.value["name"], port)
  #     port = each.value["ports"][port]["port"]
  #   } if lower(each.value["ports"][port]["protocol"]) == "http"
  # ]
  frontend_ports = [{
      name = each.value["name"]
      port = local.api_app_gw_frontend_port
    }]
  gateway_ip_configurations = [
    {
      name      = each.value["name"]
      subnet_id = local.app_gw_subnet_id
    }
  ]
  http_listeners = [
    for port in sort(keys(each.value["ports"])) : {
      name                           = format("%s-%s-http-listener", each.value["name"], port)
      frontend_ip_configuration_name = each.value["name"]
      #frontend_port_name             = format("%s-%s-frontend-port", each.value["name"], port)
      frontend_port_name             = each.value["name"]
      host_names                     = port == "app" ? [local.api_domain] : local.ops_domain
      protocol                       = "Https" #title(each.value["ports"][port]["protocol"])
      ssl_certificate_name           = local.api_app_gw_ssl_certificate_name 
    }
  ]
  request_routing_rules = [
    for idx, port in sort(keys(each.value["ports"])) : {
      name                       = format("%s-%s-request-routing-rule", each.value["name"], port)
      http_listener_name         = format("%s-%s-http-listener", each.value["name"], port)
      rule_type                  = "Basic"
      backend_address_pool_name  = each.value["name"]
      backend_http_settings_name = format("%s-%s-http-setting", each.value["name"], port)
      priority                   = 100 + idx
    }
  ]
  ssl_certificates = [{
      name                = local.api_app_gw_ssl_certificate_name
      key_vault_secret_id = module.api_certificate.versionless_secret_id
    }]
  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
  identity = {
    identity_ids = [azurerm_user_assigned_identity.certificate_reader.id]
    type         = "UserAssigned"    
  }
  depends_on = [
    module.networking,
    module.app_security_group,
    module.certificate_key_vault,
    module.api_certificate
  ]
}

#tokkio 
data "azurerm_dns_zone" "dns_zone" {
  name = var.dns_and_certs_configs.dns_zone
}

data "azurerm_app_service_certificate_order" "wildcard_certificate" {
  name                = var.dns_and_certs_configs.wildcard_cert
  resource_group_name = var.dns_and_certs_configs.resource_group
}

data "azurerm_key_vault_secret" "wildcard_certificate_secret" {
  key_vault_id = data.azurerm_app_service_certificate_order.wildcard_certificate.certificates[0].key_vault_id
  name         = data.azurerm_app_service_certificate_order.wildcard_certificate.certificates[0].key_vault_secret_name
}

resource "azurerm_user_assigned_identity" "certificate_reader" {
  name                = format("%s-cert-reader", var.name)
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
}

module "certificate_key_vault" {
  source                    = "../modules/azure/key-vault"
  name                      = length(var.name) > 24 ? replace(var.name, "/\\W/", "") : var.name # use non-hyphenated if length exceeds 24
  resource_group_name       = module.resource_group.name
  region                    = module.resource_group.location
  access_policies           = local.certificate_vault_access_policies
  enable_rbac_authorization = false
}

module "api_certificate" {
  source       = "../modules/azure/key-vault-certificate"
  name         = var.name
  key_vault_id = module.certificate_key_vault.id
  contents     = data.azurerm_key_vault_secret.wildcard_certificate_secret.value
  password     = ""
  depends_on   = [module.certificate_key_vault.access_policy]
}

module "api_dns" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => {
      name  = format("%s-%s-app-gw", local.name, cluster)
    }
    if var.clusters[cluster].private_instance
  }
  source            = "../modules/azure/dns-a-record"
  name              = local.api_sub_domain
  base_domain       = local.base_domain
  ttl               = 3600
  azure_resource_id = null
  ip_addresses      = [module.app_gateway[each.key].public_ip[each.value["name"]]]
}

module "elastic_dns" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => {
      name  = format("%s-%s-app-gw", local.name, cluster)
    }
    if var.clusters[cluster].private_instance
  }
  source            = "../modules/azure/dns-a-record"
  name              = local.elastic_sub_domain
  base_domain       = local.base_domain
  ttl               = 3600
  azure_resource_id = null
  ip_addresses      = [module.app_gateway[each.key].public_ip[each.value["name"]]]
}

module "kibana_dns" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => {
      name  = format("%s-%s-app-gw", local.name, cluster)
    }
    if var.clusters[cluster].private_instance
  }
  source            = "../modules/azure/dns-a-record"
  name              = local.kibana_sub_domain
  base_domain       = local.base_domain
  ttl               = 3600
  azure_resource_id = null
  ip_addresses      = [module.app_gateway[each.key].public_ip[each.value["name"]]]
}

module "grafana_dns" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => {
      name  = format("%s-%s-app-gw", local.name, cluster)
    }
    if var.clusters[cluster].private_instance
  }
  source            = "../modules/azure/dns-a-record"
  name              = local.grafana_sub_domain
  base_domain       = local.base_domain
  ttl               = 3600
  azure_resource_id = null
  ip_addresses      = [module.app_gateway[each.key].public_ip[each.value["name"]]]
}

module "ui_storage_account" {
  source              = "../modules/azure/storage-account-backed-static-website"
  resource_group_name = module.resource_group.name
  region              = module.resource_group.location
  name                = local.ui_storage_account_name
  index_document      = local.ui_website_index_document
  error_404_document  = local.ui_website_error_404_document
}

module "ui_cdn" {
  source              = "../modules/azure/cdn-for-static-website"
  resource_group_name = module.resource_group.name
  target_host_name    = module.ui_storage_account.primary_web_host
  cdn_profile_name    = local.ui_cdn_profile_name
  cdn_endpoint_name   = local.ui_cdn_endpoint_name
}

module "ui_custom_domain" {
  source            = "../modules/azure/custom-domain-for-cdn"
  count             = var.include_ui_custom_domain ? 1 : 0
  cdn_endpoint_id   = module.ui_cdn.endpoint_id
  cdn_endpoint_fqdn = module.ui_cdn.endpoint_fqdn
  base_domain       = local.base_domain
  ui_sub_domain     = local.ui_sub_domain
}

resource "azurerm_user_assigned_identity" "ui_uploader" {
  name                = format("%s-ui-uploader", var.name)
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
}

resource "azurerm_role_assignment" "ui_uploader_access" {
  scope                = module.ui_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.ui_uploader.principal_id
}