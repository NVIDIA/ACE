
variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "virtual_network_address_space" {
  type = string
}

variable "subnet_details" {
  type = list(object({
    identifier            = string
    address_prefix        = string
    type                  = string
    service_endpoints     = list(string)
    nsg_identifier        = string
    associate_nat_gateway = bool
  }))
}

variable "network_security_groups" {
  type = list(object({
    identifier = string
  }))
  default = []
}

variable "network_security_rules" {
  type = list(object({
    nsg_identifier               = string
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = string
    source_port_ranges           = list(string)
    destination_port_range       = string
    destination_port_ranges      = list(string)
    source_address_prefix        = string
    source_address_prefixes      = list(string)
    destination_address_prefix   = string
    destination_address_prefixes = list(string)
    include_nat_as_source        = bool
  }))
  default = []
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}