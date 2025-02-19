
variable "base_config" {
  type = object({
    app_sg_ids               = list(string)
    coturn_sg_ids            = list(string)
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
  })
}
variable "name" {
  type = string
}
variable "coturn_settings" {
  type = object({
    realm    = string
    username = string
    password = string
  })
  sensitive = true
}

variable "coturn_ami_name" {
  type    = string
  default = null
}