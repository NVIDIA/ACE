
terraform {
  experiments = [module_variable_optional_attrs]
}
variable "provider_config" {
  type = object({
    tenant_id       = string
    subscription_id = string
    client_id       = string
    client_secret   = string
  })
}
variable "region" {
  type = string
}

variable "virtual_network_address_space" {
  type = string
}
variable "ssh_public_key" {
  type = string
}
variable "dev_source_address_prefixes" {
  type = list(string)
}
variable "user_source_address_prefixes" {
  type = list(string)
}

variable "dns_and_certs_configs" {
  type = object({
    resource_group = string
    dns_zone       = string
    wildcard_cert  = string
  })
}

variable "twilio_settings" {
  type = object({
    account_sid = string
    auth_token  = string
  })
  sensitive = true
  default   = null
}

variable "coturn_settings" {
  type = object({
    realm    = string
    username = string
    password = string
  })
  sensitive = true
  default   = null
}

variable "api_sub_domain" {
  type = string
}

variable "ui_sub_domain" {
  type = string
}
variable "include_ui_custom_domain" {
  type = bool
}

variable "vm_image_version" {
  type    = string
  default = null
}

variable "api_vm_size" {
  type    = string
  default = null
}

variable "api_vm_data_disk_size_gb" {
  type    = number
  default = null
}

variable "name" {
  type = string
}
variable "ngc_api_key" {
  type = string
}
variable "rp_vm_size" {
  type    = string
  default = null
}
variable "rp_vm_data_disk_size_gb" {
  type    = number
  default = null
}
variable "turn_server_provider" {
  type = string
  validation {
    condition     = contains(["rp", "coturn"], var.turn_server_provider)
    error_message = "The turn_server_provider must be either 'rp' or 'coturn'"
  }
  default = "rp"
}
variable "api_settings" {
  type = object({
    chart_org     = optional(string)
    chart_team    = optional(string)
    chart_name    = optional(string)
    chart_version = optional(string)
    chart_namespace = optional(object({
      api_ns          = optional(string)
      foundational_ns = optional(string)
    }))
    openai_api_key         = optional(string)
    weather_api_key        = optional(string)
    bot_config_name        = optional(string)
    context_general_search = optional(list(string))
    nemo_llm_org_team      = optional(string)
    mlops = optional(object({
      resource_group    = string
      storage_account   = string
      storage_container = string
    }))
    cns_settings = optional(object({
      cns_version = optional(string)
      cns_commit  = optional(string)
    }))
    gpu_driver_settings = optional(object({
      gpu_driver_runfile_install = optional(string)
      gpu_driver_version         = optional(string)
    }))
  })
  sensitive = true
}

variable "ui_settings" {
  type = object({
    resource_org      = optional(string)
    resource_team     = optional(string)
    resource_name     = optional(string)
    resource_version  = optional(string)
    resource_file     = optional(string)
    countdown_value   = optional(string)
    enable_countdown  = optional(bool)
    enable_camera     = optional(bool)
    app_title         = optional(string)
    application_type  = optional(string)
    overlay_visible   = optional(bool)
    ui_window_visible = optional(bool)
  })
  default = null
}

variable "ops_settings" {
  type = object({
    es_stack = optional(object({
      chart_org       = string
      chart_team      = string
      chart_name      = string
      chart_version   = string
      chart_namespace = string
    }))
    fluentbit = optional(object({
      chart_org       = string
      chart_team      = string
      chart_name      = string
      chart_version   = string
      chart_namespace = string
    }))
    ingress_controller = optional(object({
      chart_org       = string
      chart_team      = string
      chart_name      = string
      chart_version   = string
      chart_namespace = string
    }))
    prometheus_stack = optional(object({
      chart_org       = string
      chart_team      = string
      chart_name      = string
      chart_version   = string
      chart_namespace = string
    }))
  })
  default = null
}

variable "rp_settings" {
  type = object({
    chart_org     = optional(string)
    chart_team    = optional(string)
    chart_name    = optional(string)
    chart_version = optional(string)
    cns_settings = optional(object({
      cns_version = optional(string)
      cns_commit  = optional(string)
    }))
  })
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