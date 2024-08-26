
resource "google_storage_bucket" "config_bucket" {
  name                        = local.config_bucket_details.name
  location                    = local.config_bucket_details.location
  force_destroy               = local.config_bucket_details.force_destroy
  uniform_bucket_level_access = true
}