variable "name" {
  description = "The name of the Resource Group to be created. Changing this forces new resources to be created."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Specifies the supported Azure location where the resource group should exist. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = null
}