
variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "include_public_ip" {
  type = bool
}

variable "size" {
  type = string
}

variable "zone" {
  type = string
}

variable "user_data" {
  type    = string
  default = null
}

variable "user_data_with_public_ip_placeholder" {
  type    = string
  default = null
}

variable "user_data_public_ip_placeholder_regex" {
  type    = string
  default = null
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "accelerated_networking" {
  type = bool
}

variable "image_details" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "os_disk_details" {
  type = object({
    storage_account_type = string
    disk_size_gb         = string
  })
}

variable "data_disk_details" {
  type = list(object({
    name                 = string
    storage_account_type = string
    disk_size_gb         = number
    lun                  = number
    caching              = string
  }))
  default = []
}

variable "identity" {
  type = object({
    identity_ids = list(string)
    type         = string
  })
  default = null
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}