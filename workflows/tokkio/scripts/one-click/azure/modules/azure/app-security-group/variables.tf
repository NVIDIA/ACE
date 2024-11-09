variable "application_security_groups" {
  description = "A set of application security groups to create."
  type        = set(string)
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the Resource Group where the resources should exist. Changing this forces new resources to be created."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Specifies the supported Azure location where the resource should exist. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "network_security_rules" {
  description = <<EOF
  rules                                     = Manages a Network Security Rule.
    access                                  = (Required) Specifies whether network traffic is allowed or denied. Possible values are Allow and Deny.
    direction                               = (Required) The direction specifies if rule will be evaluated on incoming or outgoing traffic. Possible values are Inbound and Outbound.
    network_security_group_name             = (Required) The name of the Network Security Group that we want to attach the rule to. Changing this forces a new resource to be created.
    rule_name                               = (Required) The name of the security rule. This needs to be unique across all Rules in the Network Security Group. Changing this forces a new resource to be created.
    priority                                = (Required) Specifies the priority of the rule. The value can be between 100 and 4096. The priority number must be unique for each rule in the collection. The lower the priority number, the higher the priority of the rule.
    protocol                                = (Required) Network protocol this rule applies to. Possible values include Tcp, Udp, Icmp, Esp, Ah or * (which matches all).
    description                             = (Optional) A description for this rule. Restricted to 140 characters.
    source_port_ranges                      = (Optional) List of source ports or port ranges. This is required if source_port_range is not specified.
    destination_port_ranges                 = (Optional) List of destination ports or port ranges. This is required if destination_port_range is not specified.
    source_address_prefixes                 = (Optional) List of source address prefixes. Tags may not be used. This is required if source_address_prefix is not specified.
    source_application_security_groups      = (Optional) A List of source Application Security Group IDs
    destination_address_prefixes            = (Optional) List of destination address prefixes. Tags may not be used. This is required if destination_address_prefix is not specified.
    destination_application_security_groups = (Optional) A List of destination Application Security Group IDs
  EOF
  type = map(object({
    access                                  = string
    direction                               = string
    network_security_group_name             = string
    rule_name                               = string
    priority                                = number
    protocol                                = string
    description                             = optional(string)
    destination_address_prefixes            = optional(list(string))
    destination_application_security_groups = optional(list(string))
    destination_port_ranges                 = optional(list(string))
    source_port_ranges                      = optional(list(string))
    source_address_prefixes                 = optional(list(string))
    source_application_security_groups      = optional(list(string))
  }))
  default  = {}
  nullable = false
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = null
}