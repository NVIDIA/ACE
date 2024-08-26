
variable "name" {
  type = string
}
variable "default_service" {
  type = string
}
variable "ssl_certificates" {
  type = list(string)
}
variable "https_port_range" {
  type = string
}
variable "http_port_range" {
  type = string
}

# variable "host_rules" {
#   type = map(object({
#     hosts = list(string)
#     path_matcher = string
#   }))
#   default = {}
# }

# variable "path_matchers" {
#   type = map(object({
#     default_service = string
#     path_rules = object({
#       paths   = list(string)
#       service = string
#     })
#   }))
#   default = {}
# }

variable "host_rules" {
  type = list(object({
    hosts        = list(string)
    path_matcher = string
  }))
  default = []
}

variable "path_matchers" {
  type = list(object({
    name            = string
    default_service = optional(string)
    path_rules = list(object({
      paths   = list(string)
      service = optional(string)
    }))
  }))
  default = []
}

variable "service" {
  type    = string
  default = null
}