
variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}