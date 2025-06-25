variable "location" {
  description = "Azure Region where the Virtual Machine exists. "
  type        = string
  nullable    = false
}

variable "name" {
  description = "The name of the virtual machine."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the Resource Group in which the Virtual Machine should exist."
  type        = string
  nullable    = false
}

variable "subnet_id" {
  description = "The ID of the subnet to use for the virtual machine."
  type        = string
  nullable    = false
}

variable "admin_username" {
  description = "Name of the local administrator account to create on the virtual machine."
  type        = string
  nullable    = false
}

variable "attach_public_ip" {
  description = "Whether to attach public ip address to the instance or not."
  type        = bool
  default     = false
}

variable "image_offer" {
  description = "The offer of the image used to create the virtual machine."
  type        = string
  nullable    = false
}

variable "image_publisher" {
  description = "The  publisher of the image used to create the virtual machine."
  type        = string
  nullable    = false
}

variable "image_sku" {
  description = "The SKU of the image used to create the virtual machine."
  type        = string
  nullable    = false
}

variable "image_version" {
  description = "The version of the image used to create the virtual machine."
  type        = string
  nullable    = false
}

variable "size" {
  description = "The size of the virtual machine."
  type        = string
  nullable    = false
}

variable "ssh_public_key" {
  description = "The Public Key which should be used for authentication, which needs to be at least 2048-bit and in ssh-rsa format."
  type        = string
  nullable    = false
}

variable "zone" {
  description = "Specifies the Availability Zones in which this Linux Virtual Machine should be located. Changing this forces a new Linux Virtual Machine to be created."
  type        = string
  default     = null
  nullable    = true
}

variable "os_disk_caching" {
  description = "The Type of Caching which should be used for the Internal OS Disk. Possible values are None, ReadOnly and ReadWrite."
  type        = string
  default     = "ReadWrite"
  nullable    = false
}

variable "os_disk_type" {
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS. Changing this forces a new resource to be created."
  type        = string
  default     = "Standard_LRS"
  nullable    = false
}

variable "os_disk_size_gb" {
  description = "The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine is sourced from."
  type        = string
  default     = null
  nullable    = true
}

variable "network_security_group_ids" {
  description = "The IDs of the Network Security Group which should be attached to the Network Interface."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "application_security_group_ids" {
  description = "The IDs of the Application Security Group which this Network Interface which should be connected to."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "public_ip_address_id" {
  description = "The public IP address id to associate with the virtual machine."
  type        = string
  default     = null
  nullable    = true
}

variable "custom_data" {
  description = "The Base64-Encoded Custom Data which should be used for this Virtual Machine. Changing this forces a new resource to be created."
  type        = string
  default     = null
  nullable    = true
}

variable "encryption_at_host_enabled" {
  description = "Should all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host?"
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "A mapping of tags which should be assigned to this Virtual Machine."
  type        = map(string)
  default     = {}
  nullable    = true
}

variable "identity" {
  type = object({
    identity_ids = list(string)
    type         = string
  })
  default = null
}

variable "data_disk_details" {
  type = list(object({
    name                 = string
    storage_account_type = string
    disk_size_gb         = number
    lun                  = number
    caching              = string
  }))
  default = []
}
