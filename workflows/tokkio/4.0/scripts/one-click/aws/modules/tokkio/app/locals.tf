
locals {
  name                = format("%s-app", var.name)
  lb_name             = var.name
  tg_name             = var.name
  ops_tg_name         = format("%s-ops-tg", var.name)
  base_domain         = var.base_config.base_domain
  elastic_sub_domain  = coalesce(var.elastic_sub_domain, format("elastic-%s", var.name))
  kibana_sub_domain   = coalesce(var.kibana_sub_domain, format("kibana-%s", var.name))
  grafana_sub_domain  = coalesce(var.grafana_sub_domain, format("grafana-%s", var.name))
  api_domain          = format("%s.%s", var.api_sub_domain, local.base_domain)
  ui_domain           = format("%s.%s", var.ui_sub_domain, local.base_domain)
  elastic_domain      = format("%s.%s", local.elastic_sub_domain, local.base_domain)
  kibana_domain       = format("%s.%s", local.kibana_sub_domain, local.base_domain)
  grafana_domain      = format("%s.%s", local.grafana_sub_domain, local.base_domain)
  ops_es_cluster_name = "tokkio-logging-es-cluster"
  cdn_cache_policy    = var.cdn_cache_enabled ? "Managed-CachingOptimized" : "Managed-CachingDisabled"
  coturn_settings = lower(var.turn_server_provider) != "coturn" ? {
    public_ip = "127.0.0.1"
    port      = 1234
    username  = "foo"
    password  = "bar"
  } : var.coturn_settings
  rp_instance_ip = var.rp_settings != null ? var.rp_settings.private_ip : ""

  twilio_settings = lower(var.turn_server_provider) != "twilio" ? {
    account_sid = ""
    auth_token  = ""
  } : var.twilio_settings

  app_instance_type_default              = "g4dn.12xlarge"
  app_instance_type                      = var.app_instance_type == null ? local.app_instance_type_default : var.app_instance_type
  app_instance_data_disk_size_gb_default = 1024
  app_instance_data_disk_size_gb         = var.app_instance_data_disk_size_gb == null ? local.app_instance_data_disk_size_gb_default : var.app_instance_data_disk_size_gb
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
    mlops = {
      bucket_name           = ""
      bucket_region         = ""
      aws_access_key_id     = ""
      aws_secret_access_key = ""
    }
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

  api_chart_url = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.api_settings["chart_org"], local.api_settings["chart_team"], local.api_settings["chart_name"], local.api_settings["chart_version"])

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


  # logging_elastic_kibana_chart_url = "https://helm.ngc.nvidia.com/nv-metropolis-dev/foundational-svcs/charts/logging-stack-elastic-kibana-0.0.2.tgz"
  logging_elastic_kibana_chart_url = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.ops_settings.es_stack["chart_org"], local.ops_settings.es_stack["chart_team"], local.ops_settings.es_stack["chart_name"], local.ops_settings.es_stack["chart_version"])
  #logging_fluentbit_chart_URL      = "https://helm.ngc.nvidia.com/lypzw7yma4rr/tokkiodev/charts/tokkio-fluent-bit-logging-service-0.0.3.tgz"
  logging_fluentbit_chart_URL = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.ops_settings.fluentbit["chart_org"], local.ops_settings.fluentbit["chart_team"], local.ops_settings.fluentbit["chart_name"], local.ops_settings.fluentbit["chart_version"])
  # prometheus_stack_chart_url       = "https://helm.ngc.nvidia.com/nv-metropolis-dev/foundational-svcs/charts/mdx-kube-prometheus-stack-1.0.4.tgz"
  prometheus_stack_chart_url = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.ops_settings.prometheus_stack["chart_org"], local.ops_settings.prometheus_stack["chart_team"], local.ops_settings.prometheus_stack["chart_name"], local.ops_settings.prometheus_stack["chart_version"])
  # ingress_controller_chart_url     = "https://helm.ngc.nvidia.com/nv-metropolis-dev/foundational-svcs/charts/mdx-nginx-ingress-controller-v1.0.tgz"
  ingress_controller_chart_url = format("https://helm.ngc.nvidia.com/%s/%s/charts/%s-%s.tgz", local.ops_settings.ingress_controller["chart_org"], local.ops_settings.ingress_controller["chart_team"], local.ops_settings.ingress_controller["chart_name"], local.ops_settings.ingress_controller["chart_version"])

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
  # ui_resource            = var.ui_resource == null ? local.ui_resource_default : var.ui_resource
  ui_resource_org        = local.ui_settings["resource_org"] == null ? local.ui_settings_defaults["resource_org"] : local.ui_settings["resource_org"]
  ui_resource_team       = local.ui_settings["resource_team"] == null ? local.ui_settings_defaults["resource_team"] : local.ui_settings["resource_team"]
  ui_resource_name       = local.ui_settings["resource_name"] == null ? local.ui_settings_defaults["resource_name"] : local.ui_settings["resource_name"]
  ui_resource_version    = local.ui_settings["resource_version"] == null ? local.ui_settings_defaults["resource_version"] : local.ui_settings["resource_version"]
  ui_resource_url        = format("%s/%s/%s:%s", local.ui_resource_org, local.ui_resource_team, local.ui_resource_name, local.ui_resource_version)
  ui_file                = local.ui_settings["resource_file"] == null ? local.ui_settings_defaults["resource_file"] : local.ui_settings["resource_file"]
  vst_endpoint           = format("https://%s:443", local.api_domain)
  ui_server_endpoint     = format("https://%s:443", local.api_domain)
  websocket_endpoint     = format("wss://%s:443/ws", local.api_domain)
  vst_websocket_endpoint = format("wss://%s:443/vms/ws", local.api_domain)
  countdown_value        = local.ui_settings["countdown_value"] == null ? local.ui_settings_defaults["countdown_value"] : local.ui_settings["countdown_value"]
  app_title              = local.ui_settings["app_title"] == null ? local.ui_settings_defaults["app_title"] : local.ui_settings["app_title"]
  enable_camera          = local.ui_settings["enable_camera"] == null ? local.ui_settings_defaults["enable_camera"] : local.ui_settings["enable_camera"]
  enable_countdown       = local.ui_settings["enable_countdown"] == null ? local.ui_settings_defaults["enable_countdown"] : local.ui_settings["enable_countdown"]
  application_type       = local.ui_settings["application_type"] == null ? local.ui_settings_defaults["application_type"] : local.ui_settings["application_type"]
  overlay_visible        = local.ui_settings["overlay_visible"] == null ? local.ui_settings_defaults["overlay_visible"] : local.ui_settings["overlay_visible"]
  ui_window_visible      = local.ui_settings["ui_window_visible"] == null ? local.ui_settings_defaults["ui_window_visible"] : local.ui_settings["ui_window_visible"]
  app_instance_details = {
    instance_type    = local.app_instance_type
    root_volume_type = "gp3"
    root_volume_size = 50
    data_disks = [
      {
        device_name = "/dev/xvdb"
        volume_size = local.app_instance_data_disk_size_gb
        volume_type = "gp3"
      }
    ]
  }

  app_ami_name_defaults = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  app_ami_name          = var.app_ami_name == null ? local.app_ami_name_defaults : var.app_ami_name
  app_ami_lookup = {
    owners = ["099720109477"] # Canonical
    filters = [
      {
        name   = "name"
        values = [local.app_ami_name]
      },
      {
        name   = "virtualization-type"
        values = ["hvm"]
      }
    ]
  }
}
