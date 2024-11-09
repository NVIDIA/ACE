variable "name" {
  type        = string
  description = "(Required) The name for the network."
  nullable    = false
}

variable "region" {
  type        = string
  description = "(Required) The GCP region in which the resources belong to."
  nullable    = false
}

variable "ip_cidr_range" {
  type        = string
  description = "(Optional) The IPv4 CIDR range for the network."
  default     = null
}