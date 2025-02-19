locals {
  name                               = format("%s-rp", var.name)
  network                            = var.base_config.vpc.network
  subnetwork                         = var.base_config.vpc.rp_subnetwork
  instance_tags                      = var.base_config.instance_tags.rp
  ssh_public_key                     = var.base_config.ssh_public_key
  region                             = var.base_config.region
  zone                               = var.base_config.zone
  config_bucket_name                 = var.base_config.config_bucket.name
  instance_machine_type_default      = "e2-standard-8"
  instance_type                      = var.instance_machine_type == null ? local.instance_machine_type_default : var.instance_machine_type
  instance_data_disk_size_gb_default = 1024
  instance_data_disk_size_gb         = var.instance_data_disk_size_gb == null ? local.instance_data_disk_size_gb_default : var.instance_data_disk_size_gb
  instance_image_defaults            = "ubuntu-2204-jammy-v20240319"
  instance_image                     = var.rp_instance_image == null ? local.instance_image_defaults : var.rp_instance_image
  instance_config = {
    name       = local.name
    network    = local.network
    subnetwork = local.subnetwork
    region     = local.region
    zone       = local.zone
    network_interface = {
      access_configs = [
        {
          network_tier = "PREMIUM"
        }
      ]
    }
    tags = local.instance_tags
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
      size_gb      = local.instance_data_disk_size_gb
      source_image = format("projects/ubuntu-os-cloud/global/images/%s", local.instance_image)
      type         = "pd-standard"
      auto_delete  = true
    }
    data_disks = [
      {
        device_name = format("%s-data", local.name)
        size_gb     = local.instance_data_disk_size_gb
        type        = "pd-standard"
        auto_delete = false
      }
    ]
    metadata_startup_script = templatefile("${path.module}/user-data/user-data.sh.tpl", {
      name           = local.name
      config_bucket  = local.config_bucket_name
      config_scripts = local.config_scripts
    })
    machine_type     = local.instance_machine_type_default
    ssh_public_key   = local.ssh_public_key
    ssh_user         = "ubuntu"
    static_public_ip = false
  }
  rp_settings_defaults = {
    chart_org     = "nvidia"
    chart_team    = "ucs-ms"
    chart_name    = "rproxy"
    chart_version = "0.0.5"
    cns_settings = {
      cns_version = "11.0"
      cns_commit  = "1abe8a8e17c7a15adb8b2585481a3f69a53e51e2"
    }
  }
  rp_settings = var.rp_settings != null ? {
    chart_org     = coalesce(var.rp_settings.chart_org, local.rp_settings_defaults.chart_org)
    chart_team    = coalesce(var.rp_settings.chart_team, local.rp_settings_defaults.chart_team)
    chart_name    = coalesce(var.rp_settings.chart_name, local.rp_settings_defaults.chart_name)
    chart_version = coalesce(var.rp_settings.chart_version, local.rp_settings_defaults.chart_version)
    cns_settings = var.rp_settings["cns_settings"] != null ? {
      cns_version = var.rp_settings["cns_settings"]["cns_version"] != null ? var.rp_settings["cns_settings"]["cns_version"] : local.rp_settings_defaults["cns_settings"]["cns_version"]
      cns_commit  = var.rp_settings["cns_settings"]["cns_commit"] != null ? var.rp_settings["cns_settings"]["cns_commit"] : local.rp_settings_defaults["cns_settings"]["cns_commit"]
    } : local.rp_settings_defaults["cns_settings"]
  } : local.rp_settings_defaults
  chart_url = format(
    "https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz",
    local.rp_settings["chart_org"],
    local.rp_settings["chart_team"],
    local.rp_settings["chart_name"],
    local.rp_settings["chart_version"]
  )

}