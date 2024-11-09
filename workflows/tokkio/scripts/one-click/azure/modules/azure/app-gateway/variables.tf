variable "location" {
  description = "The Azure region where the Application Gateway should exist. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "name" {
  description = "The name of the Application Gateway. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the resource group in which to the Application Gateway should exist. Changing this forces a new resource to be created."
  type        = string
  nullable    = false
}

variable "backend_address_pools" {
  description = <<EOF
    One or more backend_address_pool blocks as defined below:
      name         = (Required) The name of the Backend Address Pool.
      fqdns        = (Optional) A list of FQDN's which should be part of the Backend Address Pool.
      ip_addresses = (Optional) A list of IP Addresses which should be part of the Backend Address Pool.
  EOF
  type = list(object({
    name         = string
    fqdns        = optional(list(string), [])
    ip_addresses = optional(list(string), [])
  }))
  nullable = false
}

variable "backend_http_settings" {
  description = <<EOF
    A list of one or more backend_http_setting blocks as defined below:
      name                                = (Required) The name of the Backend HTTP Settings Collection.
      port                                = (Required) The port which should be used for this Backend HTTP Settings Collection.
      protocol                            = (Required) The Protocol which should be used. Possible values are Http and Https.
      affinity_cookie_name                = (Optional) The name of the affinity cookie.
      authentication_certificate          = (Optional) A list of one or more authentication_certificate_backend blocks as defined below.
        name                              = (Required) The name of the Authentication Certificate.
      connection_draining                 = (Optional) A connection_draining block as defined below.
        enabled                           = (Required) If connection draining is enabled or not.
        drain_timeout_sec                 = (Required) The number of seconds connection draining is active. Acceptable values are from 1 second to 3600 seconds.
      cookie_based_affinity               = (Optional) Is Cookie-Based Affinity enabled? Possible values are Enabled and Disabled. Defaults to Disabled.
      host_name                           = (Optional) Host header to be sent to the backend servers. Cannot be set if pick_host_name_from_backend_address is set to true.
      path                                = (Optional) The Path which should be used as a prefix for all HTTP requests.
      pick_host_name_from_backend_address = (Optional) Whether host header should be picked from the host name of the backend server. Defaults to false.
      probe_name                          = (Optional) The name of an associated HTTP Probe.
      request_timeout                     = (Optional) The request timeout in seconds, which must be between 1 and 86400 seconds. Defaults to 30.
      trusted_root_certificate_names      = (Optional) A list of trusted_root_certificate names.
  EOF
  type = list(object({
    name                 = string
    port                 = number
    protocol             = string
    affinity_cookie_name = optional(string)
    authentication_certificate = optional(list(object({
      name = string
    })), [])
    connection_draining = optional(object({
      enabled           = bool
      drain_timeout_sec = number
    }))
    cookie_based_affinity               = optional(string, "Disabled")
    host_name                           = optional(string)
    path                                = optional(string)
    pick_host_name_from_backend_address = optional(bool, false)
    probe_name                          = optional(string)
    request_timeout                     = optional(number)
    trusted_root_certificate_names      = optional(list(string))
  }))
  nullable = false
}

variable "frontend_ip_configurations" {
  description = <<EOF
    A list of one or more frontend_ip_configuration blocks as defined below:
      name                            = (Required) The name of the Frontend IP Configuration.
      private_ip_address              = (Optional) The Private IP Address to use for the Application Gateway.
      private_ip_address_allocation   = (Optional) The Allocation Method for the Private IP Address. Possible values are Dynamic and Static. Defaults to Dynamic.
      private_link_configuration_name = (Optional) The name of the private link configuration to use for this frontend IP configuration.
      public_ip_address               = (Optional) Details of the Public IP Address to create and which the Application Gateway should use. Cannot be used along with public_ip_address_id. The allocation method for the Public IP Address depends on the sku of this Application Gateway. Please refer to the Azure documentation for public IP addresses for details.
        name                          = (Required) The name of the Public IP Address.
        allocation_method             = (Optional) Defines the allocation method for this IP address. Possible values are Static or Dynamic. Defaults to Static.
        sku                           = (Optional) The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Standard. Changing this forces a new resource to be created.
      public_ip_address_id            = (Optional) The ID of a Public IP Address which the Application Gateway should use. The allocation method for the Public IP Address depends on the sku of this Application Gateway. Please refer to the Azure documentation for public IP addresses for details.
      subnet_id                       = (Optional) The ID of the Subnet.
  EOF
  type = list(object({
    name                            = string
    private_ip_address              = optional(string)
    private_ip_address_allocation   = optional(string)
    private_link_configuration_name = optional(string)
    public_ip_address = optional(object({
      name              = string
      allocation_method = optional(string, "Static")
      sku               = optional(string, "Standard")
    }))
    public_ip_address_id = optional(string)
    subnet_id            = optional(string)
  }))
  nullable = false
}

variable "frontend_ports" {
  description = <<EOF
    A list of one or more frontend_port blocks as defined below:
      name = (Required) The name of the Frontend Port.
      port = (Required) The port used for this Frontend Port.
  EOF
  type = list(object({
    name = string
    port = number
  }))
  nullable = false
}

variable "gateway_ip_configurations" {
  description = <<EOF
    A list of one or more gateway_ip_configuration blocks as defined below:
      name      = (Required) The Name of this Gateway IP Configuration.
      subnet_id = (Required) The ID of the Subnet which the Application Gateway should be connected to.
  EOF
  type = list(object({
    name      = string
    subnet_id = string
  }))
  nullable = false
}

variable "http_listeners" {
  description = <<EOF
    A list of one or more gateway_ip_configuration blocks as defined below:
      name                           = (Required) The Name of the HTTP Listener.
      frontend_ip_configuration_name = (Required) The Name of the Frontend IP Configuration used for this HTTP Listener.
      frontend_port_name             = (Required) The Name of the Frontend Port use for this HTTP Listener.
      protocol                       = (Required) The Protocol to use for this HTTP Listener. Possible values are Http and Https.
      custom_error_configuration     = (Optional) One or more custom_error_configuration blocks as defined below.
        status_code                  = (Required) Status code of the application gateway customer error. Possible values are HttpStatus403 and HttpStatus502
        custom_error_page_url        = (Required) Error page URL of the application gateway customer error.
      host_names                     = (Optional) A list of Hostname(s) should be used for this HTTP Listener. It allows special wildcard characters.
      require_sni                    = (Optional) Should Server Name Indication be Required? Defaults to false.
      ssl_certificate_name           = (Optional) The name of the associated SSL Certificate which should be used for this HTTP Listener.
      firewall_policy_id             = (Optional) The ID of the Web Application Firewall Policy which should be used for this HTTP Listener.
      ssl_profile_name               = (Optional) The name of the associated SSL Profile which should be used for this HTTP Listener.
  EOF
  type = list(object({
    name                           = string
    frontend_ip_configuration_name = string
    frontend_port_name             = string
    protocol                       = string
    host_names                     = optional(list(string), [])
    require_sni                    = optional(bool, false)
    ssl_certificate_name           = optional(string)
    custom_error_configuration = optional(list(object({
      status_code           = string
      custom_error_page_url = string
    })), [])
    firewall_policy_id = optional(string)
    ssl_profile_name   = optional(string)
  }))
  nullable = false
}

variable "request_routing_rules" {
  description = <<EOF
    A list of one or more request_routing_rule blocks as defined below:
      name                        = (Required) The Name of this Request Routing Rule.
      http_listener_name          = (Required) The Name of the HTTP Listener which should be used for this Routing Rule.
      rule_type                   = (Required) The Type of Routing that should be used for this Rule. Possible values are Basic and PathBasedRouting.
      backend_address_pool_name   = (Optional) The Name of the Backend Address Pool which should be used for this Routing Rule. Cannot be set if redirect_configuration_name is set.
      backend_http_settings_name  = (Optional) The Name of the Backend HTTP Settings Collection which should be used for this Routing Rule. Cannot be set if redirect_configuration_name is set.
      redirect_configuration_name = (Optional) The Name of the Redirect Configuration which should be used for this Routing Rule. Cannot be set if either backend_address_pool_name or backend_http_settings_name is set.
      rewrite_rule_set_name       = (Optional) The Name of the Rewrite Rule Set which should be used for this Routing Rule. Only valid for v2 SKUs.
      url_path_map_name           = (Optional) The Name of the URL Path Map which should be associated with this Routing Rule.
      priority                    = (Optional) Rule evaluation order can be dictated by specifying an integer value from 1 to 20000 with 1 being the highest priority and 20000 being the lowest priority.
  EOF
  type = list(object({
    name                        = string
    http_listener_name          = string
    rule_type                   = string
    backend_address_pool_name   = optional(string)
    backend_http_settings_name  = optional(string)
    redirect_configuration_name = optional(string)
    rewrite_rule_set_name       = optional(string)
    url_path_map_name           = optional(string)
    priority                    = optional(number)
  }))
  nullable = false
}

variable "sku" {
  description = <<EOF
    A sku block as defined below:
      name     = (Required) The Name of the SKU to use for this Application Gateway. Possible values are Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2.
      tier     = (Required) The Tier of the SKU to use for this Application Gateway. Possible values are Standard, Standard_v2, WAF and WAF_v2.
      capacity = (Optional) The Capacity of the SKU to use for this Application Gateway. When using a V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU. This property is optional if autoscale_configuration is set.
  EOF
  type = object({
    name     = string
    tier     = string
    capacity = optional(number)
  })
  nullable = false
}

variable "identity" {
  description = <<EOF
    (Optional) An identity block as defined below:
      type         = (Required) Specifies the type of Managed Service Identity that should be configured on this Application Gateway. Only possible value is UserAssigned.
      identity_ids = (Required) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Application Gateway.
  EOF
  type = object({
    type         = string
    identity_ids = list(string)
  })
  nullable = true
  default  = null
}

variable "probes" {
  description = <<EOF
    A list of zero or more probe blocks as defined below:
      name                                      = (Required) The Name of the Probe.
      path                                      = (Required) The Path used for this Probe.
      protocol                                  = (Required) The Protocol used for this Probe. Possible values are Http and Https.
      host                                      = (Optional) The Hostname used for this Probe. If the Application Gateway is configured for a single site, by default the Host name should be specified as 127.0.0.1, unless otherwise configured in custom probe. Cannot be set if pick_host_name_from_backend_http_settings is set to true.
      interval                                  = (Optional) The Interval between two consecutive probes in seconds. Possible values range from 1 second to a maximum of 86,400 seconds. Defaults to 30.
      match                                     = (Optional) A match block as defined above.
        status_code                             = (Required) A list of allowed status codes for this Health Probe.
        body                                    = (Optional) A snippet from the Response Body which must be present in the Response.
      minimum_servers                           = (Optional) The minimum number of servers that are always marked as healthy. Defaults to 0.
      pick_host_name_from_backend_http_settings = (Optional) Whether the host header should be picked from the backend HTTP settings. Defaults to false.
      port                                      = (Optional) Custom port which will be used for probing the backend servers. The valid value ranges from 1 to 65535. In case not set, port from HTTP settings will be used. This property is valid for Standard_v2 and WAF_v2 only.
      timeout                                   = (Optional) The Timeout used for this Probe, which indicates when a probe becomes unhealthy. Possible values range from 1 second to a maximum of 86,400 seconds. Defaults to 30.
      unhealthy_threshold                       = (Optional) The Unhealthy Threshold for this Probe, which indicates the amount of retries which should be attempted before a node is deemed unhealthy. Possible values are from 1 to 20. Defaults to 3.
  EOF
  type = list(object({
    name     = string
    path     = string
    protocol = string
    host     = optional(string)
    interval = optional(number, 30)
    match = optional(object({
      status_code = list(string)
      body        = optional(string)
    }))
    minimum_servers                           = optional(number)
    pick_host_name_from_backend_http_settings = optional(bool, false)
    port                                      = optional(number)
    timeout                                   = optional(number, 30)
    unhealthy_threshold                       = optional(number, 3)
  }))
  nullable = false
  default  = []
}

variable "ssl_certificates" {
  description = <<EOF
    A list of zero or more ssl_certificate blocks as defined below:
      name                = (Required) The Name of the SSL certificate that is unique within this Application Gateway
      data                = (Optional) The base64-encoded PFX certificate data. Required if key_vault_secret_id is not set.
      password            = (Optional) Password for the pfx file specified in data. Required if data is set.
      key_vault_secret_id = (Optional) The Secret ID of (base-64 encoded unencrypted pfx) the Secret or Certificate object stored in Azure KeyVault. You need to enable soft delete for Key Vault to use this feature. Required if data is not set.
  EOF
  type = list(object({
    name                = string
    data                = optional(string)
    password            = optional(string)
    key_vault_secret_id = optional(string)
  }))
  nullable = false
  default  = []
}