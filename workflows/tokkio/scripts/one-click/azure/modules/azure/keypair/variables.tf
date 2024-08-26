
variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "public_key" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}