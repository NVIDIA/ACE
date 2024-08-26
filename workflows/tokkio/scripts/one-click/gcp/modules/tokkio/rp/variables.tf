
variable "name" {
  type = string
}

variable "base_config" {
  type = object({
    vpc = object({
      network       = string
      rp_subnetwork = string
    })
    region = string
    zone   = string
    config_bucket = object({
      name = string
    })
    instance_tags = object({
      rp = list(string)
    })
    ssh_public_key = string
  })
}

variable "instance_machine_type" {
  type    = string
  default = null
}

variable "instance_data_disk_size_gb" {
  type    = number
  default = null
}
variable "rp_instance_image" {
  type    = string
  default = null
}
variable "instance_suffixes" {
  type = list(string)
}

variable "ngc_api_key" {
  type      = string
  sensitive = true
}

variable "rp_settings" {
  type = object({
    chart_org     = string
    chart_team    = string
    chart_name    = string
    chart_version = string
    cns_settings = object({
      cns_version = string
      cns_commit  = string
    })
  })
  default = null
}

