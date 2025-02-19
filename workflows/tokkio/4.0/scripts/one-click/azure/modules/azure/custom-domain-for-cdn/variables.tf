
variable "cdn_endpoint_id" {
  type = string
}

variable "cdn_endpoint_fqdn" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "ui_sub_domain" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}