variable "name" {
  type = string
}

variable "controller_ip" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "additional_ssh_public_keys" {
  type    = list(string)
  default = []
}

variable "clusters" {
  type = map(object({
    bastion = optional(object({
      user = string
      host = string
    }))
    master = object({
      user   = string
      host   = string
      labels = optional(map(string), {})
      taints = optional(list(object({
        key      = optional(string)
        operator = optional(string)
        value    = optional(string)
        effect   = optional(string)
      })), [])
    })
    nodes = optional(map(object({
      user   = string
      host   = string
      labels = optional(map(string), {})
      taints = optional(list(object({
        key      = optional(string)
        operator = optional(string)
        value    = optional(string)
        effect   = optional(string)
      })), [])
    })), {})
    ports = optional(map(object({
      port     = number
      protocol = optional(string, "http")
      path     = optional(string, "/")
    })), {})
    features = optional(map(bool), {})
  }))
}

variable "turn_server_provider" {
  type = string
  validation {
    condition     = contains(["rp", "coturn", "twilio"], var.turn_server_provider)
    error_message = "The turn_server_provider must be either 'rp' or 'coturn' or 'twilio"
  }
  default = "coturn"
}