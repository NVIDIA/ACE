
variable "name" {
  type = string
}
variable "base_config" {
  type = object({
    rp_sg_ids                = list(string)
    config_bucket            = string
    config_access_policy_arn = string
    keypair = object({
      name = string
    })
    networking = object({
      vpc_id            = string
      public_subnet_ids = list(string)
    })
  })
}
variable "instance_suffixes" {
  type = list(string)
}
variable "ngc_api_key" {
  type      = string
  sensitive = true
}
variable "instance_type" {
  type    = string
  default = null
}
variable "instance_data_disk_size_gb" {
  type    = number
  default = null
}
variable "rp_ami_name" {
  type    = string
  default = null
}
variable "rp_settings" {
  type = object({
    chart_org     = string
    chart_team    = string
    chart_name    = string
    chart_version = string
    cns_settings = object({
      cns_version = string
      cns_commit  = string
    })
  })
  default = null
}