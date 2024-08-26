
variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "virtual_network_address_space" {
  type = string
}
variable "ssh_public_key" {
  type = string
}
variable "dev_source_address_prefixes" {
  type = list(string)
}
variable "user_source_address_prefixes" {
  type = list(string)
}
variable "dns_and_certs_configs" {
  type = object({
    resource_group = string
    dns_zone       = string
    wildcard_cert  = string
  })
}

variable "bastion_vm_image_version" {
  type    = string
  default = null
}