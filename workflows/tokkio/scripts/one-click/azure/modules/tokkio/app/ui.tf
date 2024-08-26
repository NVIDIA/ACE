
module "ui_storage_account" {
  source              = "../../azure/storage-account-backed-static-website"
  resource_group_name = var.base_config.resource_group.name
  region              = var.base_config.networking.region
  name                = local.ui_storage_account_name
  index_document      = local.ui_website_index_document
  error_404_document  = local.ui_website_error_404_document
}

module "ui_cdn" {
  source              = "../../azure/cdn-for-static-website"
  resource_group_name = var.base_config.resource_group.name
  target_host_name    = module.ui_storage_account.primary_web_host
  cdn_profile_name    = local.ui_cdn_profile_name
  cdn_endpoint_name   = local.ui_cdn_endpoint_name
}

module "ui_custom_domain" {
  source            = "../../azure/custom-domain-for-cdn"
  count             = var.include_ui_custom_domain ? 1 : 0
  cdn_endpoint_id   = module.ui_cdn.endpoint_id
  cdn_endpoint_fqdn = module.ui_cdn.endpoint_fqdn
  base_domain       = local.base_domain
  ui_sub_domain     = var.ui_sub_domain
}

resource "azurerm_user_assigned_identity" "ui_uploader" {
  name                = format("%s-ui-uploader", var.name)
  resource_group_name = var.base_config.resource_group.name
  location            = var.base_config.networking.region
}

resource "azurerm_role_assignment" "ui_uploader_access" {
  scope                = module.ui_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.ui_uploader.principal_id
}