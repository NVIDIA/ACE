
variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "index_document" {
  type = string
}

variable "error_404_document" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}