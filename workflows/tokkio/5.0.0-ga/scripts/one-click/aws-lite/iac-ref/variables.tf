variable "name" {
  type = string
}

variable "provider_config" {
  type = object({
    access_key = string
    secret_key = string
  })
}
variable "user_access_cidrs" {
  type = list(string)
}
variable "dev_access_cidrs" {
  type = list(string)
}

variable "region" {
  type = string
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

variable "ami" {
  type = object({
    most_recent = optional(bool, true)
    owners      = optional(list(string), ["099720109477"])
    filters = optional(map(list(string)), {
      name                = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
      virtualization-type = ["hvm"]
    })
  })
  default = {
    most_recent = true
    owners      = ["099720109477"]
    filters = {
      name                = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
      virtualization-type = ["hvm"]
    }
  }
}

variable "turn_server_provider" {
  type = string
  validation {
    condition     = contains(["rp", "coturn", "twilio"], var.turn_server_provider)
    error_message = "The turn_server_provider must be either 'rp' or 'coturn' or 'twilio"
  }
  default = "coturn"
}

variable "clusters" {
  type = map(object({
    private_instance = optional(bool, false)
    use_twilio_stun_turn = optional(bool, false)
    use_reverse_proxy = optional(bool, false)
    master = optional(object({
      type              = optional(string, "g4dn.12xlarge")
      az                = optional(string)
      disk_size_gb      = optional(number, 128)
      data_disk_size_gb = optional(number, 1024)
      labels            = optional(map(string), {})
      taints = optional(list(object({
        key      = optional(string)
        operator = optional(string)
        value    = optional(string)
        effect   = optional(string)
      })), [])
      }), {
      type              = "g4dn.12xlarge"
      az                = null
      disk_size_gb      = 128
      data_disk_size_gb = 1024
      labels            = {}
      taints            = []
    })
    nodes = optional(map(object({
      type         = optional(string, "g4dn.xlarge")
      az           = optional(string)
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
      port              = number
      protocol          = optional(string, "http")
      path              = optional(string, "/")
      health_check_port = optional(number)
    })), {})
    features = optional(map(bool), {})
  }))
}

variable "controller_ip" {
  type = string
}