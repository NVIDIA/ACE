
resource "google_storage_bucket_object" "mount_data_disk" {
  bucket = local.config_bucket_name
  name   = format("%s/mount-data-disk.sh", local.name)
  content = templatefile("${path.module}/config/mount-data-disk.sh.tpl", {
    data_disk_device_name = local.data_disk_device_name
  })
}

resource "google_storage_bucket_object" "install_cns" {
  bucket  = local.config_bucket_name
  name    = format("%s/install-cns.sh", local.name)
  content = file("${path.module}/config/install-cns.sh")
}

resource "google_storage_bucket_object" "setup_foundational_charts" {
  bucket  = local.config_bucket_name
  name    = format("%s/setup-foundational-charts.sh", local.name)
  content = file("${path.module}/config/setup-foundational-charts.sh")
}

resource "google_storage_bucket_object" "setup_ops_components" {
  bucket  = local.config_bucket_name
  name    = format("%s/setup-ops-components.sh", local.name)
  content = file("${path.module}/config/setup-ops-components.sh")
}

resource "google_storage_bucket_object" "verify_gpu_operator_ready" {
  bucket  = local.config_bucket_name
  name    = format("%s/verify-gpu-operator-ready.sh", local.name)
  content = file("${path.module}/config/verify-gpu-operator-ready.sh")
}

resource "google_storage_bucket_object" "install_ngc_cli" {
  bucket  = local.config_bucket_name
  name    = format("%s/install-ngc-cli.sh", local.name)
  content = file("${path.module}/config/install-ngc-cli.sh")
}

resource "google_storage_bucket_object" "tokkio_env" {
  bucket = local.config_bucket_name
  name   = format("%s/tokkio-env.sh", local.name)
  content = templatefile("${path.module}/config/tokkio-env.sh.tpl", {
    name                             = local.name
    use_twilio                       = lower(var.turn_server_provider) == "twilio"
    twilio                           = local.twilio_settings
    coturn                           = local.coturn_settings
    ngc_api_key                      = var.ngc_api_key
    ui_bucket                        = module.ui_bucket.name
    ui_domain                        = local.ui_domain
    api_domain                       = local.api_domain
    api_chart_url                    = local.api_chart_url
    openai_api_key                   = local.api_settings.openai_api_key
    weather_api_key                  = local.api_settings.weather_api_key
    bot_config_name                  = local.api_settings.bot_config_name
    context_general_search           = join("|", local.api_settings.context_general_search)
    rp_instance_ip                   = local.rp_instance_ip
    use_reverse_proxy                = lower(var.turn_server_provider) == "rp"
    nemo_llm_org_team                = local.api_settings.nemo_llm_org_team
    mlops                            = local.api_settings.mlops
    ui_resource_url                  = local.ui_resource_url
    ui_file                          = local.ui_file
    countdown_value                  = local.countdown_value
    app_title                        = local.app_title
    enable_camera                    = local.enable_camera
    enable_countdown                 = local.enable_countdown
    application_type                 = local.application_type
    overlay_visible                  = local.overlay_visible
    ui_window_visible                = local.ui_window_visible
    vst_endpoint                     = local.vst_endpoint
    ui_server_endpoint               = local.ui_server_endpoint
    websocket_endpoint               = local.websocket_endpoint
    vst_websocket_endpoint           = local.vst_websocket_endpoint
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

resource "google_storage_bucket_object" "setup_tokkio_secrets" {
  bucket  = local.config_bucket_name
  name    = format("%s/setup-tokkio-secrets.sh", local.name)
  content = file("${path.module}/config/setup-tokkio-secrets.sh")
}

resource "google_storage_bucket_object" "setup_tokkio_api" {
  bucket  = local.config_bucket_name
  name    = format("%s/setup-tokkio-api.sh", local.name)
  content = file("${path.module}/config/setup-tokkio-api.sh")
}

resource "google_storage_bucket_object" "setup_tokkio_ui" {
  bucket  = local.config_bucket_name
  name    = format("%s/setup-tokkio-ui.sh", local.name)
  content = file("${path.module}/config/setup-tokkio-ui.sh")
}

locals {
  config_scripts = [
    {
      exec = "bash"
      path = google_storage_bucket_object.mount_data_disk.name
      hash = google_storage_bucket_object.mount_data_disk.md5hash
    },
    {
      exec = "source"
      path = google_storage_bucket_object.tokkio_env.name
      hash = google_storage_bucket_object.tokkio_env.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.install_cns.name
      hash = google_storage_bucket_object.install_cns.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.verify_gpu_operator_ready.name
      hash = google_storage_bucket_object.verify_gpu_operator_ready.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.install_ngc_cli.name
      hash = google_storage_bucket_object.install_ngc_cli.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.setup_tokkio_secrets.name
      hash = google_storage_bucket_object.setup_tokkio_secrets.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.setup_foundational_charts.name
      hash = google_storage_bucket_object.setup_foundational_charts.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.setup_ops_components.name
      hash = google_storage_bucket_object.setup_ops_components.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.setup_tokkio_api.name
      hash = google_storage_bucket_object.setup_tokkio_api.md5hash
    },
    {
      exec = "bash"
      path = google_storage_bucket_object.setup_tokkio_ui.name
      hash = google_storage_bucket_object.setup_tokkio_ui.md5hash
    }
  ]
}