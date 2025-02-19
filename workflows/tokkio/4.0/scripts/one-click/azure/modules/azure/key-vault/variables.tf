
variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "access_policies" {
  type = list(object({
    identifier              = string
    tenant_id               = string
    application_id          = string
    object_id               = string
    certificate_permissions = list(string)
    key_permissions         = list(string)
    secret_permissions      = list(string)
    storage_permissions     = list(string)
  }))
  default = []
}

variable "enable_rbac_authorization" {
  type = bool
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}