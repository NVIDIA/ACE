
variable "name" {
  type = string
}
variable "base_config" {
  type = object({
    resource_group = object({
      name = string
    }),
    networking = object({
      region          = string
      rp_vm_subnet_id = string
    }),
    keypair = object({
      public_key = string
    }),
    config_storage_account = object({
      id   = string
      name = string
      reader_identity = object({
        id        = string
        client_id = string
      })
      reader_access = object({
        id = string
      })
    })
  })
}

variable "rp_vm_size" {
  type    = string
  default = null
}
variable "rp_vm_data_disk_size_gb" {
  type    = number
  default = null
}
variable "rp_vm_image_version" {
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