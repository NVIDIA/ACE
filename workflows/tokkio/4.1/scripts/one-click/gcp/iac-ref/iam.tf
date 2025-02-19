
resource "google_service_account" "api_instance_service_account" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-serviceaccount", local.name, k)
      } if v.private_instance
    }
  account_id = each.value.name
}

resource "google_storage_bucket_iam_member" "api_instance_ui_bucket_write_access" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-ops-backend", local.name, k)
      } if v.private_instance
    }
  bucket = module.ui_bucket[each.key].name
  role   = "roles/storage.objectAdmin"
  member = format("serviceAccount:%s", google_service_account.api_instance_service_account[each.key].email)
}

resource "google_storage_bucket_iam_member" "ui_bucket_all_users_access" {
  for_each = {
      for k, v in var.clusters : k => {
        name = format("%s-%s-ops-backend", local.name, k)
      } if v.private_instance
    }
  bucket = module.ui_bucket[each.key].name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}