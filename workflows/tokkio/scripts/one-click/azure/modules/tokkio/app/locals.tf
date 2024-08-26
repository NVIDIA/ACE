
data "azurerm_client_config" "current" {}

locals {
  base_domain                      = var.base_config.domain_name
  wildcard_certificate_b64_content = var.base_config.wildcard_cert
  mlops = {
    account_name   = local.api_settings.mlops == null ? "" : one(data.azurerm_storage_account.mlops_storage_account.*.name)
    access_key     = local.api_settings.mlops == null ? "" : one(data.azurerm_storage_account.mlops_storage_account.*.primary_access_key)
    container_name = local.api_settings.mlops == null ? "" : one(data.azurerm_storage_container.mlops_storage_container.*.name)
  }
  ops_es_cluster_name = "tokkio-logging-es-cluster"
  coturn_settings = lower(var.turn_server_provider) != "coturn" ? {
    public_ip = "127.0.0.1"
    port      = 1234
    username  = "foo"
    password  = "bar"
  } : var.coturn_settings
  rp_instance_ip = var.rp_settings != null ? var.rp_settings.private_ip : ""
  api_vm_name    = format("%s-api", var.name)
  api_vm_config_user_data = base64encode(templatefile("${path.module}/user-data/user-data.sh.tpl", {
    config_storage_account   = var.base_config.config_storage_account.name
    config_storage_container = azurerm_storage_container.env_config_storage_container.name
    config_access_client_id  = var.base_config.config_storage_account.reader_identity.client_id
    config_scripts           = local.config_scripts
  }))

  api_vm_image_version_defaults = "latest"
  api_vm_image_version          = var.api_vm_image_version == null ? local.api_vm_image_version_defaults : var.api_vm_image_version
  api_vm_details = {
    size                   = local.api_vm_size
    zone                   = "1"
    admin_username         = "ubuntu"
    accelerated_networking = true
    image_details = {
      publisher = "canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = local.api_vm_image_version
    }
    os_disk_details = {
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 64
    }
    data_disk_details = [
      {
        name                 = "data-disk-0"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = local.api_vm_data_disk_size_gb
        lun                  = 0
        caching              = "ReadOnly"
      }
    ]
    identity = {
      identity_ids = [
        var.base_config.config_storage_account.reader_identity.id,
        azurerm_user_assigned_identity.ui_uploader.id
      ]
      type = "UserAssigned"
    }
  }

  api_app_gw_backend_address_pool_name      = format("%s-api", var.name)
  api_app_gw_backend_http_settings_name     = format("%s-api", var.name)
  api_app_gw_name                           = format("%s-api-app-gw", var.name)
  api_app_gw_public_ip_name                 = format("%s-api-app-gw", var.name)
  api_app_gw_health_probe_name              = format("%s-api-health", var.name)
  api_app_gw_health_probe_host              = "127.0.0.1"
  api_app_gw_http_listener_name             = format("%s-api", var.name)
  api_app_gw_request_routing_rule_name      = format("%s-api", var.name)
  api_app_gw_ssl_certificate_name           = format("%s-api", var.name)
  api_app_gw_frontend_ip_configuration_name = format("%s-api-app-gw", var.name)
  api_app_gw_frontend_port                  = 443
  api_app_gw_frontend_port_name             = format("%s-api-app-gw-port-%s", var.name, local.api_app_gw_frontend_port)
  api_app_gw_gateway_ip_configuration_name  = format("%s-api-app-gw", var.name)
  api_app_gw_app_port                       = 30888
  api_app_gw_app_health_port                = 30801
  api_app_gw_app_health_path                = "/health"
  api_app_gw_http_listener_host_names       = [local.api_domain]

  ops_app_gw_backend_http_settings_name = format("%s-ops", var.name)
  ops_app_gw_app_port                   = 31080
  ops_app_gw_health_probe_name          = format("%s-ops-health", var.name)
  ops_app_gw_health_probe_host          = local.elastic_domain
  ops_app_gw_http_listener_name         = format("%s-ops", var.name)
  ops_app_gw_http_listener_host_names   = [local.elastic_domain, local.kibana_domain, local.grafana_domain]
  ops_app_gw_request_routing_rule_name  = format("%s-ops", var.name)
  ops_app_gw_app_health_port            = 31080
  ops_app_gw_app_health_path            = "/_cluster/health"

  api_app_gw_settings = {
    backend_address_pools = [{
      name         = local.api_app_gw_backend_address_pool_name
      ip_addresses = [for instance_suffix in var.instance_suffixes : module.api_vm[instance_suffix].private_ip]
    }]
    probes = [{
      name                                      = local.api_app_gw_health_probe_name
      pick_host_name_from_backend_http_settings = false
      host                                      = local.api_app_gw_health_probe_host
      port                                      = local.api_app_gw_app_health_port
      protocol                                  = "Http"
      path                                      = local.api_app_gw_app_health_path
      timeout                                   = 30
      unhealthy_threshold                       = 3
      interval                                  = 30
      minimum_servers                           = 0
      match = {
        status_code = ["200-399"]
        body        = null
      }
      },
      {
        name                                      = local.ops_app_gw_health_probe_name
        pick_host_name_from_backend_http_settings = false
        host                                      = local.ops_app_gw_health_probe_host
        port                                      = local.ops_app_gw_app_health_port
        protocol                                  = "Http"
        path                                      = local.ops_app_gw_app_health_path
        timeout                                   = 30
        unhealthy_threshold                       = 3
        interval                                  = 30
        minimum_servers                           = 0
        match = {
          status_code = ["200-399"]
          body        = null
        }
    }]
    backend_http_settings = [{
      name                                = local.api_app_gw_backend_http_settings_name
      pick_host_name_from_backend_address = false
      host_name                           = null
      port                                = local.api_app_gw_app_port
      protocol                            = "Http"
      path                                = null
      probe_name                          = local.api_app_gw_health_probe_name
      cookie_based_affinity               = "Disabled"
      affinity_cookie_name                = "ApplicationGatewayAffinity"
      request_timeout                     = 20
      trusted_root_certificate_names      = []
      },
      {
        name                                = local.ops_app_gw_backend_http_settings_name
        pick_host_name_from_backend_address = false
        host_name                           = null
        port                                = local.ops_app_gw_app_port
        protocol                            = "Http"
        path                                = null
        probe_name                          = local.ops_app_gw_health_probe_name
        cookie_based_affinity               = "Disabled"
        affinity_cookie_name                = "ApplicationGatewayAffinity"
        request_timeout                     = 20
        trusted_root_certificate_names      = []
    }]
    frontend_ip_configurations = [{
      name           = local.api_app_gw_frontend_ip_configuration_name
      public_ip_name = local.api_app_gw_public_ip_name
    }]
    frontend_ports = [{
      name = local.api_app_gw_frontend_port_name
      port = local.api_app_gw_frontend_port
    }]
    gateway_ip_configurations = [{
      name      = local.api_app_gw_gateway_ip_configuration_name
      subnet_id = var.base_config.networking.api_app_gw_subnet_id
    }]
    http_listeners = [
      {
        name                           = local.api_app_gw_http_listener_name
        protocol                       = "Https"
        frontend_ip_configuration_name = local.api_app_gw_frontend_ip_configuration_name
        frontend_port_name             = local.api_app_gw_frontend_port_name
        host_names                     = local.api_app_gw_http_listener_host_names
        require_sni                    = false
        ssl_certificate_name           = local.api_app_gw_ssl_certificate_name
      },
      {
        name                           = local.ops_app_gw_http_listener_name
        protocol                       = "Https"
        frontend_ip_configuration_name = local.api_app_gw_frontend_ip_configuration_name
        frontend_port_name             = local.api_app_gw_frontend_port_name
        host_names                     = local.ops_app_gw_http_listener_host_names
        require_sni                    = false
        ssl_certificate_name           = local.api_app_gw_ssl_certificate_name
    }]
    request_routing_rules = [
      {
        name                       = local.api_app_gw_request_routing_rule_name
        backend_address_pool_name  = local.api_app_gw_backend_address_pool_name
        backend_http_settings_name = local.api_app_gw_backend_http_settings_name
        http_listener_name         = local.api_app_gw_http_listener_name
        priority                   = 100
        rule_type                  = "Basic"
      },
      {
        name                       = local.ops_app_gw_request_routing_rule_name
        backend_address_pool_name  = local.api_app_gw_backend_address_pool_name
        backend_http_settings_name = local.ops_app_gw_backend_http_settings_name
        http_listener_name         = local.ops_app_gw_http_listener_name
        priority                   = 110
        rule_type                  = "Basic"
    }]
    ssl_certificates = [{
      name                = local.api_app_gw_ssl_certificate_name
      key_vault_secret_id = module.api_certificate.versionless_secret_id
    }]

  }


  api_vm_size_default              = "Standard_NC64as_T4_v3"
  api_vm_size                      = var.api_vm_size == null ? local.api_vm_size_default : var.api_vm_size
  api_vm_data_disk_size_gb_default = 1024
  api_vm_data_disk_size_gb         = var.api_vm_data_disk_size_gb == null ? local.api_vm_data_disk_size_gb_default : var.api_vm_data_disk_size_gb

  api_settings_defaults = {
    chart_org     = "nvidia"
    chart_team    = "ucs-ms"
    chart_name    = "ucs-tokkio-audio-video-app"
    chart_version = "4.1.0"
    chart_namespace = {
      api_ns          = "default"
      foundational_ns = "foundational"
    }
    openai_api_key         = ""
    weather_api_key        = ""
    bot_config_name        = ""
    context_general_search = []
    nemo_llm_org_team      = ""
    mlops                  = null
    cns_settings = {
      cns_version = "11.0"
      cns_commit  = "1abe8a8e17c7a15adb8b2585481a3f69a53e51e2"
    }
    gpu_driver_settings = {
      gpu_driver_runfile_install = "true"
      gpu_driver_version         = "default"
    }
  }

  api_settings = var.api_settings != null ? {
    chart_org     = var.api_settings["chart_org"] != null ? var.api_settings["chart_org"] : local.api_settings_defaults["chart_org"]
    chart_team    = var.api_settings["chart_team"] != null ? var.api_settings["chart_team"] : local.api_settings_defaults["chart_team"]
    chart_name    = var.api_settings["chart_name"] != null ? var.api_settings["chart_name"] : local.api_settings_defaults["chart_name"]
    chart_version = var.api_settings["chart_version"] != null ? var.api_settings["chart_version"] : local.api_settings_defaults["chart_version"]
    chart_namespace = var.api_settings["chart_namespace"] != null ? {
      api_ns          = var.api_settings["chart_namespace"]["api_ns"] != null ? var.api_settings["chart_namespace"]["api_ns"] : local.api_settings_defaults["chart_namespace"]["api_ns"]
      foundational_ns = var.api_settings["chart_namespace"]["foundational_ns"] != null ? var.api_settings["chart_namespace"]["foundational_ns"] : local.api_settings_defaults["chart_namespace"]["foundational_ns"]
    } : local.api_settings_defaults["chart_namespace"]
    openai_api_key         = var.api_settings["openai_api_key"] != null ? var.api_settings["openai_api_key"] : local.api_settings_defaults["openai_api_key"]
    weather_api_key        = var.api_settings["weather_api_key"] != null ? var.api_settings["weather_api_key"] : local.api_settings_defaults["weather_api_key"]
    bot_config_name        = var.api_settings["bot_config_name"] != null ? var.api_settings["bot_config_name"] : local.api_settings_defaults["bot_config_name"]
    context_general_search = var.api_settings["context_general_search"] != null ? var.api_settings["context_general_search"] : local.api_settings_defaults["context_general_search"]
    nemo_llm_org_team      = var.api_settings["nemo_llm_org_team"] != null ? var.api_settings["nemo_llm_org_team"] : local.api_settings_defaults["nemo_llm_org_team"]
    mlops                  = var.api_settings["mlops"] != null ? var.api_settings["mlops"] : local.api_settings_defaults["mlops"]
    cns_settings = var.api_settings["cns_settings"] != null ? {
      cns_version = var.api_settings["cns_settings"]["cns_version"] != null ? var.api_settings["cns_settings"]["cns_version"] : local.api_settings_defaults["cns_settings"]["cns_version"]
      cns_commit  = var.api_settings["cns_settings"]["cns_commit"] != null ? var.api_settings["cns_settings"]["cns_commit"] : local.api_settings_defaults["cns_settings"]["cns_commit"]
    } : local.api_settings_defaults["cns_settings"]
    gpu_driver_settings = var.api_settings["gpu_driver_settings"] != null ? {
      gpu_driver_runfile_install = var.api_settings["gpu_driver_settings"]["gpu_driver_runfile_install"] != null ? var.api_settings["gpu_driver_settings"]["gpu_driver_runfile_install"] : local.api_settings_defaults["gpu_driver_settings"]["gpu_driver_runfile_install"]
      gpu_driver_version         = var.api_settings["gpu_driver_settings"]["gpu_driver_version"] != null ? var.api_settings["gpu_driver_settings"]["gpu_driver_version"] : local.api_settings_defaults["gpu_driver_settings"]["gpu_driver_version"]
    } : local.api_settings_defaults["gpu_driver_settings"]
  } : local.api_settings_defaults

  api_chart_url      = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.api_settings["chart_org"], local.api_settings["chart_team"], local.api_settings["chart_name"], local.api_settings["chart_version"])
  api_domain         = format("%s.%s", var.api_sub_domain, local.base_domain)
  api_endpoint       = format("https://%s", local.api_domain)
  elastic_sub_domain = coalesce(var.elastic_sub_domain, format("elastic-%s", var.name))
  kibana_sub_domain  = coalesce(var.kibana_sub_domain, format("kibana-%s", var.name))
  grafana_sub_domain = coalesce(var.grafana_sub_domain, format("grafana-%s", var.name))
  elastic_domain     = format("%s.%s", local.elastic_sub_domain, local.base_domain)
  kibana_domain      = format("%s.%s", local.kibana_sub_domain, local.base_domain)
  grafana_domain     = format("%s.%s", local.grafana_sub_domain, local.base_domain)

  ops_settings_defaults = {
    es_stack = {
      chart_org       = "nvidia"
      chart_team      = "ucs-ms"
      chart_name      = "logging-stack-elastic-kibana"
      chart_version   = "0.0.2"
      chart_namespace = "ops"
    }
    fluentbit = {
      chart_org       = "nvidia"
      chart_team      = "ucs-ms"
      chart_name      = "tokkio-fluent-bit-logging-service"
      chart_version   = "0.0.3"
      chart_namespace = "ops"
    }
    ingress_controller = {
      chart_org       = "nvidia"
      chart_team      = "ucs-ms"
      chart_name      = "mdx-nginx-ingress-controller"
      chart_version   = "1.0.0"
      chart_namespace = "ops"
    }
    prometheus_stack = {
      chart_org       = "nvidia"
      chart_team      = "ucs-ms"
      chart_name      = "mdx-kube-prometheus-stack"
      chart_version   = "1.0.4"
      chart_namespace = "ops"
    }
  }


  ops_settings = var.ops_settings != null ? {
    es_stack           = var.ops_settings["es_stack"] != null ? var.ops_settings["es_stack"] : local.ops_settings_defaults["es_stack"]
    fluentbit          = var.ops_settings["fluentbit"] != null ? var.ops_settings["fluentbit"] : local.ops_settings_defaults["fluentbit"]
    ingress_controller = var.ops_settings["ingress_controller"] != null ? var.ops_settings["ingress_controller"] : local.ops_settings_defaults["ingress_controller"]
    prometheus_stack   = var.ops_settings["prometheus_stack"] != null ? var.ops_settings["prometheus_stack"] : local.ops_settings_defaults["prometheus_stack"]

  } : local.ops_settings_defaults


  logging_elastic_kibana_chart_url = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.ops_settings.es_stack["chart_org"], local.ops_settings.es_stack["chart_team"], local.ops_settings.es_stack["chart_name"], local.ops_settings.es_stack["chart_version"])
  logging_fluentbit_chart_URL      = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.ops_settings.fluentbit["chart_org"], local.ops_settings.fluentbit["chart_team"], local.ops_settings.fluentbit["chart_name"], local.ops_settings.fluentbit["chart_version"])
  prometheus_stack_chart_url       = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.ops_settings.prometheus_stack["chart_org"], local.ops_settings.prometheus_stack["chart_team"], local.ops_settings.prometheus_stack["chart_name"], local.ops_settings.prometheus_stack["chart_version"])
  ingress_controller_chart_url     = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.ops_settings.ingress_controller["chart_org"], local.ops_settings.ingress_controller["chart_team"], local.ops_settings.ingress_controller["chart_name"], local.ops_settings.ingress_controller["chart_version"])



  twilio_settings = lower(var.turn_server_provider) != "twilio" ? {
    account_sid = ""
    auth_token  = ""
  } : var.twilio_settings


  ui_settings_defaults = {
    resource_org      = "nvidia"
    resource_team     = "ucs-ms"
    resource_name     = "tokkio_ui"
    resource_version  = "4.0.4"
    resource_file     = "ui.tar.gz"
    countdown_value   = "90"
    app_title         = ""
    enable_camera     = true
    enable_countdown  = false
    application_type  = ""
    overlay_visible   = true
    ui_window_visible = false
  }
  ui_settings = var.ui_settings == null ? local.ui_settings_defaults : var.ui_settings

  ui_resource_org     = local.ui_settings["resource_org"] == null ? local.ui_settings_defaults["resource_org"] : local.ui_settings["resource_org"]
  ui_resource_team    = local.ui_settings["resource_team"] == null ? local.ui_settings_defaults["resource_team"] : local.ui_settings["resource_team"]
  ui_resource_name    = local.ui_settings["resource_name"] == null ? local.ui_settings_defaults["resource_name"] : local.ui_settings["resource_name"]
  ui_resource_version = local.ui_settings["resource_version"] == null ? local.ui_settings_defaults["resource_version"] : local.ui_settings["resource_version"]
  ui_resource_url     = format("%s/%s/%s:%s", local.ui_resource_org, local.ui_resource_team, local.ui_resource_name, local.ui_resource_version)
  ui_file             = local.ui_settings["resource_file"] == null ? local.ui_settings_defaults["resource_file"] : local.ui_settings["resource_file"]





  ui_storage_account_name       = replace(format("%s-ui", var.name), "/\\W/", "")
  ui_cdn_profile_name           = format("%s-cdn", var.name)
  ui_cdn_endpoint_name          = var.ui_sub_domain
  ui_website_index_document     = "index.html"
  ui_website_error_404_document = "index.html"
  vst_endpoint                  = format("https://%s:443", local.api_domain)
  ui_server_endpoint            = format("https://%s:443", local.api_domain)
  websocket_endpoint            = format("wss://%s:443/ws", local.api_domain)
  vst_websocket_endpoint        = format("wss://%s:443/vms/ws", local.api_domain)

  countdown_value   = local.ui_settings["countdown_value"] == null ? local.ui_settings_defaults["countdown_value"] : local.ui_settings["countdown_value"]
  app_title         = local.ui_settings["app_title"] == null ? "" : local.ui_settings["app_title"]
  enable_camera     = local.ui_settings["enable_camera"] == null ? local.ui_settings_defaults["enable_camera"] : local.ui_settings["enable_camera"]
  enable_countdown  = local.ui_settings["enable_countdown"] == null ? local.ui_settings_defaults["enable_countdown"] : local.ui_settings["enable_countdown"]
  application_type  = local.ui_settings["application_type"] == null ? local.ui_settings_defaults["application_type"] : local.ui_settings["application_type"]
  overlay_visible   = local.ui_settings["overlay_visible"] == null ? local.ui_settings_defaults["overlay_visible"] : local.ui_settings["overlay_visible"]
  ui_window_visible = local.ui_settings["ui_window_visible"] == null ? local.ui_settings_defaults["ui_window_visible"] : local.ui_settings["ui_window_visible"]
  ui_domain         = var.include_ui_custom_domain ? one(module.ui_custom_domain.*.custom_domain_fqdn) : module.ui_cdn.endpoint_fqdn
  ui_endpoint       = format("https://%s", local.ui_domain)
  tenant_id         = data.azurerm_client_config.current.tenant_id
  object_id         = data.azurerm_client_config.current.object_id
  certificate_vault_access_policies = [
    {
      identifier     = "creator"
      tenant_id      = local.tenant_id
      application_id = ""
      object_id      = local.object_id
      certificate_permissions = [
        "Get",
        "List",
        "Update",
        "Create",
        "Import",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
        "ManageContacts",
        "ManageIssuers",
        "GetIssuers",
        "ListIssuers",
        "SetIssuers",
        "DeleteIssuers",
        "Purge"
      ]
      key_permissions = [
        "Get",
        "List",
        "Update",
        "Create",
        "Import",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
        "GetRotationPolicy",
        "SetRotationPolicy",
        "Rotate"
      ]
      secret_permissions = [
        "Get",
        "List",
        "Set",
        "Delete",
        "Recover",
        "Backup",
        "Restore"
      ]
      storage_permissions = []
    },
    {
      identifier     = "cert-reader"
      tenant_id      = azurerm_user_assigned_identity.certificate_reader.tenant_id
      application_id = ""
      object_id      = azurerm_user_assigned_identity.certificate_reader.principal_id
      certificate_permissions = [
        "Get",
        "List",
        "GetIssuers",
        "ListIssuers"
      ]
      key_permissions = []
      secret_permissions = [
        "Get",
        "List"
      ]
      storage_permissions = []
    }
  ]
}