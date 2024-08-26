
variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "subnets" {
  type = list(object({
    name                     = string
    ip_cidr_range            = string
    private_ip_google_access = bool
    private                  = bool
  }))
}
variable "router_bgp" {
  type = object({
    advertise_mode     = string
    advertised_groups  = list(string)
    asn                = number
    keepalive_interval = number
  })
  default = null
}
variable "firewalls" {
  type = list(object({
    name     = string
    priority = number
    allow = list(object({
      protocol = string
      ports    = list(any)
    }))
    nat_source    = bool
    source_ranges = list(string)
    source_tags   = list(string)
    target_tags   = list(string)
  }))
}