
terraform {
  experiments = [module_variable_optional_attrs]
}
variable "provider_config" {
  type = object({
    project     = string
    credentials = string
  })
}

variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "ui_bucket_location" {
  type = object({
    location         = string
    region           = string
    alternate_region = string
  })
}

variable "network_cidr_range" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "dev_access_cidrs" {
  type = list(string)
}

variable "user_access_cidrs" {
  type = list(string)
}
variable "dns_zone_name" {
  type = string
}
variable "api_sub_domain" {
  type = string
}
variable "ui_sub_domain" {
  type = string
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
variable "ngc_api_key" {
  type = string
}
variable "api_instance_machine_type" {
  type    = string
  default = null
}
variable "api_instance_data_disk_size_gb" {
  type    = number
  default = null
}
variable "instance_image" {
  type    = string
  default = null
}
variable "turn_server_provider" {
  type = string
  validation {
    condition     = contains(["coturn", "rp"], var.turn_server_provider)
    error_message = "The turn_server_provider must be either 'coturn' or 'rp'"
  }
  default = "rp"
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
      bucket_name  = string
      uploader_key = string
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
  default   = null
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
variable "rp_instance_machine_type" {
  type    = string
  default = null
}
variable "rp_instance_data_disk_size_gb" {
  type    = number
  default = null
}