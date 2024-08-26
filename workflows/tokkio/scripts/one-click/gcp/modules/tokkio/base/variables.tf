
variable "name" {
  type = string
}
variable "location" {
  type = string
}
variable "region" {
  type = string
}
variable "zone" {
  type = string
}
variable "network_cidr_range" {
  type = string
}
variable "ssh_public_key" {
  type = string
}
variable "dev_access_cidrs" {
  type = list(string)
}
variable "user_access_cidrs" {
  type = list(string)
}
variable "bastion_instance_image" {
  type    = string
  default = null
}
variable "ui_bucket_location" {
  type = object({
    location         = string
    region           = string
    alternate_region = string
  })
}