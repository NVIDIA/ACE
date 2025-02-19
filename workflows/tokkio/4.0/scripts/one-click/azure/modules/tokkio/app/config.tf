
resource "azurerm_storage_container" "env_config_storage_container" {
  name                  = format("%s-app", var.name)
  storage_account_name  = var.base_config.config_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "mount_data_disk" {
  name                   = "mount-data-disk.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/mount-data-disk.sh")
}

resource "azurerm_storage_blob" "install_cnc" {
  name                   = "install-cnc.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/install-cnc.sh")
}

resource "azurerm_storage_blob" "verify_gpu_operator_ready" {
  name                   = "verify-gpu-operator-ready.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/verify-gpu-operator-ready.sh")
}

resource "azurerm_storage_blob" "tokkio_env" {
  name                   = "tokkio-env.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content = templatefile("${path.module}/config/tokkio-env.sh.tpl", {
    name                             = var.name
    use_twilio                       = lower(var.turn_server_provider) == "twilio"
    coturn                           = local.coturn_settings
    twilio                           = local.twilio_settings
    ngc_api_key                      = var.ngc_api_key
    weather_api_key                  = local.api_settings.weather_api_key
    openai_api_key                   = local.api_settings.openai_api_key
    ui_end_point                     = local.ui_endpoint
    api_domain                       = local.api_domain
    api_chart_url                    = local.api_chart_url
    ui_resource_url                  = local.ui_resource_url
    ui_file                          = local.ui_file
    ui_storage_account_name          = module.ui_storage_account.name
    ui_storage_access_client_id      = azurerm_user_assigned_identity.ui_uploader.client_id
    mlops_azureblob_account          = local.mlops.account_name
    mlops_azureblob_key              = local.mlops.access_key
    mlops_bucket_name                = local.mlops.container_name
    vst_endpoint                     = local.vst_endpoint
    ui_server_endpoint               = local.ui_server_endpoint
    websocket_endpoint               = local.websocket_endpoint
    vst_websocket_endpoint           = local.vst_websocket_endpoint
    countdown_value                  = local.countdown_value
    enable_countdown                 = local.enable_countdown
    enable_camera                    = local.enable_camera
    app_title                        = local.app_title
    bot_config_name                  = local.api_settings.bot_config_name
    context_general_search           = join("|", local.api_settings.context_general_search)
    nemo_llm_org_team                = local.api_settings.nemo_llm_org_team
    application_type                 = local.application_type
    overlay_visible                  = local.overlay_visible
    ui_window_visible                = local.ui_window_visible
    use_reverse_proxy                = lower(var.turn_server_provider) == "rp"
    rp_instance_ip                   = local.rp_instance_ip
    ops_es_cluster_name              = local.ops_es_cluster_name
    elastic_domain                   = local.elastic_domain
    kibana_domain                    = local.kibana_domain
    grafana_domain                   = local.grafana_domain
    ingress_controller_chart_url     = local.ingress_controller_chart_url
    logging_elastic_kibana_chart_url = local.logging_elastic_kibana_chart_url
    logging_fluentbit_chart_URL      = local.logging_fluentbit_chart_URL
    prometheus_stack_chart_url       = local.prometheus_stack_chart_url
    api_ns                           = local.api_settings.chart_namespace.api_ns
    ops_ns                           = local.ops_settings.es_stack.chart_namespace
    foundational_ns                  = local.api_settings.chart_namespace.foundational_ns
    cns_commit                       = local.api_settings.cns_settings.cns_commit
    cns_version                      = local.api_settings.cns_settings.cns_version
    gpu_driver_runfile_install       = local.api_settings.gpu_driver_settings.gpu_driver_runfile_install
    gpu_driver_version               = local.api_settings.gpu_driver_settings.gpu_driver_version
  })
}

resource "azurerm_storage_blob" "apply_tokkio_secrets" {
  name                   = "apply-tokkio-secrets.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/apply-tokkio-secrets.sh")
}

resource "azurerm_storage_blob" "setup_foundational_charts" {
  name                   = "setup-foundational-charts.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/setup-foundational-charts.sh")
}

resource "azurerm_storage_blob" "setup_ops_components" {
  name                   = "setup-ops-components.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/setup-ops-components.sh")
}

resource "azurerm_storage_blob" "install_tokkio_api" {
  name                   = "install-tokkio-api.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/install-tokkio-api.sh")
}

resource "azurerm_storage_blob" "install_tokkio_ui" {
  name                   = "install-tokkio-ui.sh"
  storage_account_name   = var.base_config.config_storage_account.name
  storage_container_name = azurerm_storage_container.env_config_storage_container.name
  type                   = "Block"
  source_content         = file("${path.module}/config/install-tokkio-ui.sh")
}

locals {
  config_scripts = [
    {
      exec = "bash"
      name = azurerm_storage_blob.mount_data_disk.name
      hash = sha256(azurerm_storage_blob.mount_data_disk.source_content)
    },
    {
      exec = "source"
      name = azurerm_storage_blob.tokkio_env.name
      hash = sha256(azurerm_storage_blob.tokkio_env.source_content)
    },
    {
      exec = "bash"
      name = azurerm_storage_blob.install_cnc.name
      hash = sha256(azurerm_storage_blob.install_cnc.source_content)
    },
    {
      exec = "bash"
      name = azurerm_storage_blob.verify_gpu_operator_ready.name
      hash = sha256(azurerm_storage_blob.verify_gpu_operator_ready.source_content)
    },
    {
      exec = "bash"
      name = azurerm_storage_blob.apply_tokkio_secrets.name
      hash = sha256(azurerm_storage_blob.apply_tokkio_secrets.source_content)
    },
    {
      exec = "bash"
      name = azurerm_storage_blob.setup_foundational_charts.name
      hash = sha256(azurerm_storage_blob.setup_foundational_charts.source_content)
    },

    {
      exec = "bash"
      name = azurerm_storage_blob.setup_ops_components.name
      hash = sha256(azurerm_storage_blob.setup_ops_components.source_content)
    },

    {
      exec = "bash"
      name = azurerm_storage_blob.install_tokkio_api.name
      hash = sha256(azurerm_storage_blob.install_tokkio_api.source_content)
    },

    {
      exec = "bash"
      name = azurerm_storage_blob.install_tokkio_ui.name
      hash = sha256(azurerm_storage_blob.install_tokkio_ui.source_content)
    }
  ]
}
