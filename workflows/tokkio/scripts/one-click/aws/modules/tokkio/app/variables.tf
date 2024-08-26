
variable "name" {
  type = string
}
variable "base_config" {
  type = object({
    app_sg_ids               = list(string)
    alb_sg_ids               = list(string)
    coturn_sg_ids            = list(string)
    base_domain              = string
    config_bucket            = string
    config_access_policy_arn = string
    keypair = object({
      name = string
    })
    networking = object({
      vpc_id             = string
      public_subnet_ids  = list(string)
      private_subnet_ids = list(string)
    })
    star_alb_certificate = object({
      arn = string
    })
    star_cloudfront_certificate = object({
      arn = string
    })
  })
}
variable "rp_settings" {
  type = object({
    private_ip = string
    public_ip  = string
  })
}
variable "turn_server_provider" {
  type = string
}
variable "ngc_api_key" {
  type      = string
  sensitive = true
}
variable "coturn_settings" {
  type = object({
    public_ip = string
    port      = number
    username  = string
    password  = string
  })
  default   = null
  sensitive = true
}
variable "twilio_settings" {
  type = object({
    account_sid = string
    auth_token  = string
  })
  sensitive = true
  default   = null
}

variable "instance_suffixes" {
  type = list(string)
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
variable "cdn_cache_enabled" {
  type = bool
}
variable "app_instance_type" {
  type    = string
  default = null
}
variable "app_instance_data_disk_size_gb" {
  type    = number
  default = null
}
variable "app_ami_name" {
  type    = string
  default = null
}
variable "ops_settings" {
  type = object({
    es_stack = object({
      chart_org       = string
      chart_team      = string
      chart_name      = string
      chart_version   = string
      chart_namespace = string
    })
    fluentbit = object({
      chart_org       = string
      chart_team      = string
      chart_name      = string
      chart_version   = string
      chart_namespace = string
    })
    ingress_controller = object({
      chart_org       = string
      chart_team      = string
      chart_name      = string
      chart_version   = string
      chart_namespace = string
    })
    prometheus_stack = object({
      chart_org       = string
      chart_team      = string
      chart_name      = string
      chart_version   = string
      chart_namespace = string
    })
  })
  default = null
}
variable "api_settings" {
  type = object({
    chart_org     = string
    chart_team    = string
    chart_name    = string
    chart_version = string
    chart_namespace = object({
      api_ns          = string
      foundational_ns = string
    })
    openai_api_key         = string
    weather_api_key        = string
    bot_config_name        = string
    context_general_search = list(string)
    nemo_llm_org_team      = string
    mlops = object({
      bucket_name           = string
      bucket_region         = string
      aws_access_key_id     = string
      aws_secret_access_key = string
    })
    cns_settings = object({
      cns_version = string
      cns_commit  = string
    })
    gpu_driver_settings = object({
      gpu_driver_runfile_install = string
      gpu_driver_version         = string
    })
  })
  default = null
}
variable "ui_settings" {
  type = object({
    resource_org      = string
    resource_team     = string
    resource_name     = string
    resource_version  = string
    resource_file     = string
    countdown_value   = string
    enable_countdown  = bool
    enable_camera     = bool
    app_title         = string
    application_type  = string
    overlay_visible   = bool
    ui_window_visible = bool
  })
  default = null
}
