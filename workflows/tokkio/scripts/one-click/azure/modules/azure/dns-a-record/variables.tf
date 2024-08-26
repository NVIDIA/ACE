
variable "name" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "ttl" {
  type = number
}

variable "ip_addresses" {
  type = list(string)
}

variable "azure_resource_id" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}