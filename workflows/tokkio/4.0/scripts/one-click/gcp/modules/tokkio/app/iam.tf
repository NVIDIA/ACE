
resource "google_service_account" "api_instance_service_account" {
  account_id = local.api_instance_config.name
}

resource "google_storage_bucket_iam_member" "api_instance_config_viewer_access" {
  bucket = local.config_bucket_name
  role   = "roles/storage.objectViewer"
  member = format("serviceAccount:%s", google_service_account.api_instance_service_account.email)
}

resource "google_storage_bucket_iam_member" "api_instance_ui_bucket_write_access" {
  bucket = module.ui_bucket.name
  role   = "roles/storage.objectAdmin"
  member = format("serviceAccount:%s", google_service_account.api_instance_service_account.email)
}

resource "google_storage_bucket_iam_member" "ui_bucket_all_users_access" {
  bucket = module.ui_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}