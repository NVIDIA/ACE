
variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "replication_type" {
  type    = string
  default = "LRS"
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}