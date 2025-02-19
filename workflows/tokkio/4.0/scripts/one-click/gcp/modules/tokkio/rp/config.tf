
resource "google_storage_bucket_object" "mount_data_disk" {
  bucket  = local.config_bucket_name
  name    = format("%s/mount-data-disk.sh", local.name)
  content = file("${path.module}/config/mount-data-disk.sh")
}

resource "google_storage_bucket_object" "install_cns" {
  bucket  = local.config_bucket_name
  name    = format("%s/install-cns.sh", local.name)
  content = file("${path.module}/config/install-cns.sh")
}

resource "google_storage_bucket_object" "install_gcloud_cli" {
  bucket  = local.config_bucket_name
  name    = format("%s/install-gcloud-cli.sh", local.name)
  content = file("${path.module}/config/install-gcloud-cli.sh")
}

resource "google_storage_bucket_object" "rp_env" {
  bucket = local.config_bucket_name
  name   = format("%s/rp-env.sh", local.name)
  content = templatefile("${path.module}/config/rp-env.sh.tpl", {
    ngc_api_key = var.ngc_api_key
    chart_url   = local.chart_url
    cns_commit  = local.rp_settings.cns_settings.cns_commit
    cns_version = local.rp_settings.cns_settings.cns_version
  })
}

resource "google_storage_bucket_object" "setup_rp_secrets" {
  bucket  = local.config_bucket_name
  name    = format("%s/setup-rp-secrets.sh", local.name)
  content = file("${path.module}/config/setup-rp-secrets.sh")
}


resource "google_storage_bucket_object" "install_rp_chart" {
  bucket  = local.config_bucket_name
  name    = format("%s/install-rp-chart.sh", local.name)
  content = file("${path.module}/config/install-rp-chart.sh")
}

locals {
  config_scripts = [
    {
      exec = "bash"
      path = google_storage_bucket_object.mount_data_disk.name
      hash = google_storage_bucket_object.mount_data_disk.md5hash
    },
    {
      exec = "source"
      path = google_storage_bucket_object.rp_env.name
      hash = google_storage_bucket_object.rp_env.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.install_cns.name
      hash = google_storage_bucket_object.install_cns.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.install_gcloud_cli.name
      hash = google_storage_bucket_object.install_gcloud_cli.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.setup_rp_secrets.name
      hash = google_storage_bucket_object.setup_rp_secrets.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.install_rp_chart.name
      hash = google_storage_bucket_object.install_rp_chart.md5hash
    }
  ]
}