
variable "name" {
  type = string
}
variable "base_config" {
  type = object({
    resource_group = object({
      name = string
    }),
    networking = object({
      region              = string
      coturn_vm_subnet_id = string
    }),
    keypair = object({
      public_key = string
    }),
    config_storage_account = object({
      id   = string
      name = string
      reader_identity = object({
        id        = string
        client_id = string
      })
      reader_access = object({
        id = string
      })
    })
  })
}
variable "turnserver_realm" {
  type = string
}
variable "turnserver_username" {
  type      = string
  sensitive = true
}
variable "turnserver_password" {
  type      = string
  sensitive = true
}
variable "coturn_vm_image_version" {
  type    = string
  default = null
}