
variable "name" {
  type = string
}
variable "base_config" {
  type = object({
    vpc = object({
      network           = string
      coturn_subnetwork = string
    })
    region = string
    zone   = string
    config_bucket = object({
      name = string
    })
    instance_tags = object({
      coturn = list(string)
    })
    ssh_public_key = string
  })
}
variable "coturn_settings" {
  type = object({
    realm    = string
    username = string
    password = string
  })
  sensitive = true
}
variable "coturn_instance_image" {
  type    = string
  default = null
}