
resource "google_storage_bucket_object" "coturn_server_env" {
  bucket = local.config_bucket_name
  name   = format("%s/coturn-server-env.sh", local.name)
  content = templatefile("${path.module}/config/coturn-server-env.sh.tpl", {
    coturn = var.coturn_settings
  })
}

resource "google_storage_bucket_object" "setup_coturn_server" {
  bucket  = local.config_bucket_name
  name    = format("%s/setup-coturn-server.sh", local.name)
  content = file("${path.module}/config/setup-coturn-server.sh")
}

locals {
  config_scripts = [
    {
      exec = "source"
      path = google_storage_bucket_object.coturn_server_env.name
      hash = google_storage_bucket_object.coturn_server_env.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.setup_coturn_server.name
      hash = google_storage_bucket_object.setup_coturn_server.md5hash
    }
  ]
}