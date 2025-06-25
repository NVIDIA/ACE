
data "azurerm_dns_zone" "dns_zone" {
  name = var.base_domain
}

resource "azurerm_dns_cname_record" "custom_domain_cname_record" {
  name                = var.ui_sub_domain
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = data.azurerm_dns_zone.dns_zone.resource_group_name
  ttl                 = 3600
  target_resource_id = replace(
    replace(
      var.cdn_endpoint_id,
      "Microsoft.Cdn",
      "microsoft.cdn"
    ),
    "resourcegroups",
    "resourceGroups"
  )
}

resource "azurerm_dns_cname_record" "custom_domain_cdnverify_cname_record" {
  name                = format("cdnverify.%s", var.ui_sub_domain)
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = data.azurerm_dns_zone.dns_zone.resource_group_name
  ttl                 = 3600
  record              = format("cdnverify.%s", var.cdn_endpoint_fqdn)
}

resource "azurerm_cdn_endpoint_custom_domain" "custom_domain" {
  name = replace(local.custom_domain_fqdn, ".", "-")
  cdn_endpoint_id = replace(
    replace(
      var.cdn_endpoint_id,
      "microsoft.cdn",
      "Microsoft.Cdn"
    ),
    "resourcegroups",
    "resourceGroups"
  )
  host_name = local.custom_domain_fqdn
  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
  timeouts {}
}

locals {
  custom_domain_fqdn = format(
    "%s.%s",
    var.ui_sub_domain,
    data.azurerm_dns_zone.dns_zone.name
  )
}