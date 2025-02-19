
resource "aws_s3_object" "mount_data_disk" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/mount-data-disk.sh", local.name)
  content = file("${path.module}/config/mount-data-disk.sh")
}

resource "aws_s3_object" "install_cnc" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/install-cnc.sh", local.name)
  content = file("${path.module}/config/install-cnc.sh")
}

resource "aws_s3_object" "verify_gpu_operator_ready" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/verify-gpu-operator-ready.sh", local.name)
  content = file("${path.module}/config/verify-gpu-operator-ready.sh")
}

resource "aws_s3_object" "install_aws_cli" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/install-aws-cli.sh", local.name)
  content = file("${path.module}/config/install-aws-cli.sh")
}

resource "aws_s3_object" "install_ngc_cli" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/install-ngc-cli.sh", local.name)
  content = file("${path.module}/config/install-ngc-cli.sh")
}

resource "aws_s3_object" "tokkio_env" {
  bucket = var.base_config.config_bucket
  key    = format("%s/tokkio-env.sh", local.name)
  content = templatefile("${path.module}/config/tokkio-env.sh.tpl", {
    name                             = local.name
    use_twilio                       = lower(var.turn_server_provider) == "twilio"
    twilio                           = local.twilio_settings
    coturn                           = local.coturn_settings
    ngc_api_key                      = var.ngc_api_key
    weather_api_key                  = local.api_settings.weather_api_key
    openai_api_key                   = local.api_settings.openai_api_key
    ui_domain                        = local.ui_domain
    api_domain                       = local.api_domain
    api_chart_url                    = local.api_chart_url
    ui_resource_url                  = local.ui_resource_url
    ui_file                          = local.ui_file
    mlops                            = local.api_settings.mlops
    ui_bucket                        = aws_s3_bucket.ui_bucket.id
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
    rp_instance_ip                   = local.rp_instance_ip
    use_reverse_proxy                = lower(var.turn_server_provider) == "rp"
    nemo_llm_org_team                = local.api_settings.nemo_llm_org_team
    application_type                 = local.application_type
    overlay_visible                  = local.overlay_visible
    ui_window_visible                = local.ui_window_visible
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

resource "aws_s3_object" "setup_tokkio_secrets" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/setup-tokkio-secrets.sh", local.name)
  content = file("${path.module}/config/setup-tokkio-secrets.sh")
}

resource "aws_s3_object" "setup_foundational_charts" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/setup-foundational-charts.sh", local.name)
  content = file("${path.module}/config/setup-foundational-charts.sh")
}

resource "aws_s3_object" "setup_tokkio_api" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/setup-tokkio-api.sh", local.name)
  content = file("${path.module}/config/setup-tokkio-api.sh")
}

resource "aws_s3_object" "setup_ops_components" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/setup-ops-components.sh", local.name)
  content = file("${path.module}/config/setup-ops-components.sh")
}

resource "aws_s3_object" "setup_tokkio_ui" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/setup-tokkio-ui.sh", local.name)
  content = file("${path.module}/config/setup-tokkio-ui.sh")
}

locals {
  config_scripts = [
    {
      exec = "bash"
      path = aws_s3_object.mount_data_disk.key
      hash = sha256(aws_s3_object.mount_data_disk.content)
    },
    {
      exec = "source"
      path = aws_s3_object.tokkio_env.key
      hash = sha256(aws_s3_object.tokkio_env.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.install_cnc.key
      hash = sha256(aws_s3_object.install_cnc.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.verify_gpu_operator_ready.key
      hash = sha256(aws_s3_object.verify_gpu_operator_ready.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.install_aws_cli.key
      hash = sha256(aws_s3_object.install_aws_cli.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.install_ngc_cli.key
      hash = sha256(aws_s3_object.install_ngc_cli.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.setup_tokkio_secrets.key
      hash = sha256(aws_s3_object.setup_tokkio_secrets.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.setup_foundational_charts.key
      hash = sha256(aws_s3_object.setup_foundational_charts.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.setup_ops_components.key
      hash = sha256(aws_s3_object.setup_ops_components.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.setup_tokkio_api.key
      hash = sha256(aws_s3_object.setup_tokkio_api.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.setup_tokkio_ui.key
      hash = sha256(aws_s3_object.setup_tokkio_ui.content)
    }
  ]
}