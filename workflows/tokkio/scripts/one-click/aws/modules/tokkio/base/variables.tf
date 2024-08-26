
variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "dev_access_ipv4_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "dev_access_ipv6_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "user_access_ipv4_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "user_access_ipv6_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "base_domain" {
  type = string
}

variable "bastion_ami_name" {
  type    = string
  default = null
}