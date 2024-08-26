
locals {
  name                               = format("%s-rp", var.name)
  instance_type_default              = "t3.large"
  instance_type                      = var.instance_type == null ? local.instance_type_default : var.instance_type
  instance_data_disk_size_gb_default = 1024
  instance_data_disk_size_gb         = var.instance_data_disk_size_gb == null ? local.instance_data_disk_size_gb_default : var.instance_data_disk_size_gb
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
  instance_details = {
    instance_type    = local.instance_type
    root_volume_type = "gp3"
    root_volume_size = 50
    data_disks = [
      {
        device_name = "/dev/xvdb"
        volume_size = local.instance_data_disk_size_gb
        volume_type = "gp3"
      }
    ]
  }

  rp_ami_name_defaults = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  rp_ami_name          = var.rp_ami_name == null ? local.rp_ami_name_defaults : var.rp_ami_name
  app_ami_lookup = {
    owners = ["099720109477"] # Canonical
    filters = [
      {
        name   = "name"
        values = [local.rp_ami_name]
      },
      {
        name   = "virtualization-type"
        values = ["hvm"]
      }
    ]
  }
}