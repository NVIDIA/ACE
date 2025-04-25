variable "name" {
  type        = string
  description = "The name for the VPC."
  nullable    = false
}

variable "vpc_cidr_block" {
  type        = string
  description = "The IPv4 CIDR block for the VPC."
  default     = null
}

variable "availability_zone_names" {
  type        = list(string)
  description = "The name of the availability zones to create subnets in."
  default     = []
}