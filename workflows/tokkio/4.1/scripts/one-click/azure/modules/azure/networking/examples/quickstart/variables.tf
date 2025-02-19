variable "name" {
  type        = string
  description = "The name for the Virtual Network."
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the resources should exist. Changing this forces new resources to be created."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Specifies the supported Azure location where the resource should exist. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "virtual_network_address_space" {
  type        = string
  description = "The address space that is used to create the virtual network."
  default     = "10.0.0.0/16"
  nullable    = false
}

variable "public_subnets" {
  type        = list(string)
  description = "The pubic subnets to be created."
  default     = ["public-a"]
  nullable    = false
}

variable "private_subnets" {
  type        = list(string)
  description = "The private subnets to be created."
  default     = ["private-a"]
  nullable    = false
}

variable "subnet_delegations" {
  type = map(map(object({
    service_delegation = object({
      name    = string
      actions = optional(list(string))
    })
  })))
  description = "Delegations for the provided subnets"
  default     = {}
  nullable    = false
}