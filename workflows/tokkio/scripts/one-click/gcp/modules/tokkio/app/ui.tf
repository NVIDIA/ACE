
module "ui_bucket" {
  source                   = "../../gcp/website-bucket"
  name                     = local.ui_bucket_config.name
  location                 = local.ui_bucket_config.location
  region                   = local.ui_bucket_config.region
  alternate_region         = local.ui_bucket_config.alternate_region
  force_destroy            = local.ui_bucket_config.force_destroy
  website_main_page_suffix = local.ui_bucket_config.website_main_page_suffix
  website_not_found_page   = local.ui_bucket_config.website_not_found_page
}

module "ui_backend" {
  source           = "../../gcp/compute-backend-bucket"
  name             = local.ui_backend_config.name
  bucket_name      = module.ui_bucket.name
  enable_cdn       = local.ui_backend_config.enable_cdn
  compression_mode = local.ui_backend_config.compression_mode
}

module "ui_load_balancer" {
  source           = "../../gcp/global-load-balancer"
  name             = local.ui_lb_config.name
  default_service  = module.ui_backend.id
  ssl_certificates = [google_compute_managed_ssl_certificate.certificate.id]
  https_port_range = local.ui_lb_config.https_port_range
  http_port_range  = local.ui_lb_config.http_port_range
}