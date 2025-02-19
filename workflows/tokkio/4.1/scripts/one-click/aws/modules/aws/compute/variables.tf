variable "instance_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "public_key" {
  type = string
}

variable "root_volume_type" {
  type    = string
  default = "gp3"
}

variable "root_volume_size" {
  type    = number
  default = 100
}

variable "instance_profile_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}

variable "security_groups" {
  type    = list(string)
  default = []
}

variable "user_data" {
  type    = string
  default = ""
}

variable "include_elastic_ip" {
  type    = bool
  default = true
}

variable "ebs_block_devices" {
  type = list(object({
    device_name = string
    volume_size = number
    volume_type = string
  }))
  default = []
}