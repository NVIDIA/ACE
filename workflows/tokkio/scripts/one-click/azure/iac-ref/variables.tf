variable "name" {
  type = string
}

variable "provider_config" {
  type = object({
    tenant_id       = string
    subscription_id = string
    client_id       = string
    client_secret   = string
  })
}

variable "location" {
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

variable "encryption_at_host_enabled" {
  type     = bool
  default  = false
  nullable = false
}

variable "bastion" {
  type = object({
    size         = optional(string, "Standard_B2s")
    zone         = optional(string)
    disk_size_gb = optional(number, 128)
  })
  default = {
    size         = "Standard_B2s"
    zone         = null
    disk_size_gb = 128
  }
}

variable "clusters" {
  type = map(object({
    private_instance = optional(bool, false)
    master = optional(object({
      size         = optional(string, "Standard_NC4as_T4_v3")
      zone         = optional(string)
      disk_size_gb = optional(number, 100)
      data_disk_size_gb = optional(number, 1024)
      labels       = optional(map(string), {})
      taints = optional(list(object({
        key      = optional(string)
        operator = optional(string)
        value    = optional(string)
        effect   = optional(string)
      })), [])
      }), {
      size         = "Standard_NC4as_T4_v3"
      zone         = null
      disk_size_gb = 100
      data_disk_size_gb = 1024
      labels       = {}
      taints       = []
    })
    nodes = optional(map(object({
      size         = optional(string, "Standard_NC4as_T4_v3")
      zone         = optional(string)
      disk_size_gb = optional(number, 1024)
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
      health_check_port = optional(number)
    })), {
      app = {
        health_check_port = 30801
        port          = 30888
        path          = "health"
        protocol = "http"
      }
      ops = {
        health_check_port = 31080
        port = 31080
        protocol = "http"
        path     = "/_cluster/health"
      }
    })
    features = optional(map(bool), {})
  }))
}

variable "image" {
  type = object({
    publisher = optional(string, "canonical")
    offer     = optional(string, "0001-com-ubuntu-server-jammy")
    sku       = optional(string, "22_04-lts-gen2")
    version   = optional(string, "latest")
  })
  default = {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "dns_and_certs_configs" {
  type = object({
    resource_group = string
    dns_zone       = string
    wildcard_cert  = string
  })
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
variable "api_sub_domain" {
  type    = string
  default = null
}
variable "ui_sub_domain" {
  type = string
  default = null
}
variable "include_ui_custom_domain" { 
  type = bool
}

variable "turn_server_provider" {
  type = string
  validation {
    condition     = contains(["rp", "coturn", "twilio"], var.turn_server_provider)
    error_message = "The turn_server_provider must be either 'rp' or 'coturn' or 'twilio"
  }
  default = "coturn"
}