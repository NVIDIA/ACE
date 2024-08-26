
variable "name" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "contents" {
  type = string
}

variable "password" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}