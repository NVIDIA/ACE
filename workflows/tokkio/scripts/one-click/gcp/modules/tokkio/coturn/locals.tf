
locals {
  name                    = format("%s-coturn", var.name)
  network                 = var.base_config.vpc.network
  subnetwork              = var.base_config.vpc.coturn_subnetwork
  instance_tags           = var.base_config.instance_tags.coturn
  ssh_public_key          = var.base_config.ssh_public_key
  region                  = var.base_config.region
  zone                    = var.base_config.zone
  config_bucket_name      = var.base_config.config_bucket.name
  instance_image_defaults = "ubuntu-2204-jammy-v20240319"
  instance_image          = var.coturn_instance_image == null ? local.instance_image_defaults : var.coturn_instance_image
  instance_config = {
    name       = local.name
    network    = local.network
    subnetwork = local.subnetwork
    network_interface = {
      access_configs = [
        {
          network_tier = "PREMIUM"
        }
      ]
    }
    tags         = local.instance_tags
    machine_type = "e2-medium"
    service_account_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
    boot_disk = {
      device_name  = format("%s-boot", local.name)
      size_gb      = 50
      source_image = format("projects/ubuntu-os-cloud/global/images/%s", local.instance_image)
      type         = "pd-standard"
      auto_delete  = true
    }
    ssh_public_key = local.ssh_public_key
    ssh_user       = "ubuntu"
    metadata_startup_script = templatefile("${path.module}/user-data/user-data.sh.tpl", {
      name           = local.name
      config_bucket  = local.config_bucket_name
      config_scripts = local.config_scripts
    })
    region           = local.region
    zone             = local.zone
    static_public_ip = true
  }
}