
variable "resource_group_name" {
  type = string
}

variable "target_host_name" {
  type = string
}

variable "cdn_profile_name" {
  type = string
}

variable "cdn_endpoint_name" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}