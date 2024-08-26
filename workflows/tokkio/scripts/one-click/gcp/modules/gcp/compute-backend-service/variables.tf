
variable "name" {
  type = string
}
variable "port_name" {
  type = string
}
variable "locality_lb_policy" {
  type = string
}
variable "load_balancing_scheme" {
  type = string
}
variable "group" {
  type = string
}
variable "access_policy" {
  type = object({
    rules = list(object({
      action   = string
      preview  = bool
      priority = number
      matches = list(object({
        versioned_expr = string
        configs = list(object({
          src_ip_ranges = list(string)
        }))
      }))
    }))
  })
  default = null
}
variable "http_health_checks" {
  type = list(object({
    request_path = string
    port         = number
  }))
  default = []
}