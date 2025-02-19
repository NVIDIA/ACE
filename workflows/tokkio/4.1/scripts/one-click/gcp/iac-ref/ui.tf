
module "ui_bucket" {
  for_each = {
    for k, v in var.clusters : k => {
      name = format("%s-%s-ui-bucket", local.name, k)
    } if v.private_instance
  }
  source                   = "../modules/gcp/website-bucket"
  name                     = each.value.name
  location                 = local.ui_bucket_config.location
  region                   = local.ui_bucket_config.region
  alternate_region         = local.ui_bucket_config.alternate_region
  force_destroy            = local.ui_bucket_config.force_destroy
  website_main_page_suffix = local.ui_bucket_config.website_main_page_suffix
  website_not_found_page   = local.ui_bucket_config.website_not_found_page
}

module "ui_backend" {
  for_each = {
    for k, v in var.clusters : k => {
      name = format("%s-%s-ui-backend", local.name, k)
    } if v.private_instance
  }
  source           = "../modules/gcp/compute-backend-bucket"
  name             = each.value.name
  bucket_name      = module.ui_bucket[each.key].name
  enable_cdn       = local.ui_backend_config.enable_cdn
  compression_mode = local.ui_backend_config.compression_mode
}

module "ui_load_balancer" {
  for_each = {
    for k, v in var.clusters : k => {
      name = format("%s-%s-ui-lb", local.name, k)
    } if v.private_instance
  }
  source           = "../modules/gcp/global-load-balancer"
  name             = each.value.name
  default_service  = module.ui_backend[each.key].id
  ssl_certificates = [google_compute_managed_ssl_certificate.certificate.id]
  https_port_range = local.ui_lb_config.https_port_range
  http_port_range  = local.ui_lb_config.http_port_range
}