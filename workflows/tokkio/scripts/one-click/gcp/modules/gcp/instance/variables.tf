
variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "zone" {
  type = string
}
variable "network" {
  type = string
}
variable "subnetwork" {
  type = string
}
variable "static_public_ip" {
  type = bool
}
variable "network_interface" {
  type = object({
    access_configs = list(object({
      network_tier = string
    }))
  })
}
variable "tags" {
  type = list(string)
}
variable "machine_type" {
  type = string
}
variable "service_account_email" {
  type = string
}
variable "service_account_scopes" {
  type = list(string)
}
variable "boot_disk" {
  type = object({
    device_name  = string
    size_gb      = number
    source_image = string
    type         = string
    auto_delete  = bool
  })
}
variable "data_disks" {
  type = list(object({
    device_name = string
    size_gb     = number
    type        = string
    auto_delete = bool
  }))
  default = []
}
variable "ssh_public_key" {
  type      = string
  sensitive = true
}
variable "ssh_user" {
  type = string
}
variable "additional_metadata" {
  type    = map(string)
  default = {}
}
variable "metadata_startup_script" {
  type    = string
  default = null
}
variable "advanced_machine_features" {
  type = list(object({
    enable_nested_virtualization = bool
    threads_per_core             = number
    visible_core_count           = number
  }))
  default = []
}
variable "guest_accelerators" {
  type = list(object({
    count = number
    type  = string
  }))
  default = []
}
variable "schedulings" {
  type = list(object({
    on_host_maintenance = string
  }))
  default = []
}