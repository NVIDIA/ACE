resource "google_service_account" "service_account" {
  account_id = local.name
}

resource "google_storage_bucket_iam_member" "config_viewer_access" {
  bucket = local.config_bucket_name
  role   = "roles/storage.objectViewer"
  member = format("serviceAccount:%s", google_service_account.service_account.email)
}