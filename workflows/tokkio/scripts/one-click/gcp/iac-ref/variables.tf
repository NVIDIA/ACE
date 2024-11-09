variable "name" {
  type = string
}

variable "provider_config" {
  type = object({
    project     = string
    credentials = string
  })
}

variable "region" {
  type = string
}

variable "controller_ip" {
  type = string
}

variable "user_access_cidrs" {
  type = list(string)
}

variable "dev_access_cidrs" {
  type = list(string)
}

variable "ssh_public_key" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "additional_ssh_public_keys" {
  type    = list(string)
  default = []
}

variable "bastion" {
  type = object({
    type         = optional(string, "e2-medium")
    zone         = optional(string)
    disk_size_gb = optional(number, 128)
  })
  default = {
    type         = "e2-medium"
    zone         = null
    disk_size_gb = 128
  }
}

variable "clusters" {
  type = map(object({
    private_instance = optional(bool, false)
    zone             = optional(string)
    master = optional(object({
      type = optional(string, "n1-standard-32")
      guest_accelerators = optional(list(object({
        type  = string
        count = number
      })))
      disk_size_gb = optional(number, 128)
      data_disk_size_gb = optional(number, 1024)
      labels       = optional(map(string), {})
      taints = optional(list(object({
        key      = optional(string)
        operator = optional(string)
        value    = optional(string)
        effect   = optional(string)
      })), [])
      }), {
      type               = "n1-standard-32"
      guest_accelerators = null
      disk_size_gb       = 128
      data_disk_size_gb = 1024
      labels             = {}
      taints             = []
    })
    nodes = optional(map(object({
      type = optional(string, "n1-standard-32")
      guest_accelerators = optional(list(object({
        type  = string
        count = number
      })))
      disk_size_gb = optional(number, 128)
      labels       = optional(map(string), {})
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

variable "machine_image" {
  type    = string
  default = "ubuntu-2204-jammy-v20240829"
}

variable "turn_server_provider" {
  type = string
  validation {
    condition     = contains(["rp", "coturn", "twilio"], var.turn_server_provider)
    error_message = "The turn_server_provider must be either 'rp' or 'coturn' or 'twilio"
  }
  default = "coturn"
}

variable "dns_zone_name" {
  type = string
}
variable "api_sub_domain" {
  type = string
  default = null
}
variable "ui_sub_domain" {
  type = string
  default = null
}
variable "elastic_sub_domain" {
  type    = string
  default = null
}
variable "kibana_sub_domain" {
  type    = string
  default = null
}
variable "grafana_sub_domain" {
  type    = string
  default = null
}
variable "enable_cdn" {
  type = bool
}
variable "ui_bucket_location" {
  type = object({
    location =  string
    region = string
    alternate_region = string
  })
}