
variable "instance_type" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "ami_id" {
  type    = string
  default = ""
}

variable "ami_lookup" {
  type = object({
    owners = list(string)
    filters = list(object({
      name   = string
      values = list(string)
    }))
  })
  default = {
    owners  = []
    filters = []
  }
}

variable "ec2_key" {
  type = string
}

variable "root_volume_type" {
  type = string
}

variable "root_volume_size" {
  type = number
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

variable "ingress_rules" {
  type = list(object({
    description      = string
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
    security_groups  = list(string)
    self             = bool
  }))
  default = []
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}

variable "additional_sg_ids" {
  type    = list(string)
  default = []
}

variable "user_data" {
  type    = string
  default = ""
}

variable "include_public_ip" {
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