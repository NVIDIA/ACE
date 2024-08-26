
data "google_project" "my_project" {
}

locals {
  name               = var.name
  network            = var.base_config.vpc.network
  subnetwork         = var.base_config.vpc.api_subnetwork
  instance_tags      = var.base_config.instance_tags.api
  ssh_public_key     = var.base_config.ssh_public_key
  location           = var.base_config.location
  region             = var.base_config.region
  project            = data.google_project.my_project.id
  ui_bucket_location = var.base_config.ui_bucket_location
  zone               = var.base_config.zone
  config_bucket_name = var.base_config.config_bucket.name
  user_access_cidrs  = var.base_config.user_access_cidrs
  dns_zone_name      = var.dns_zone_name
  base_dns_name      = data.google_dns_managed_zone.dns_zone.dns_name
  base_domain        = trimsuffix(local.base_dns_name, ".")
  api_sub_domain     = var.api_sub_domain
  ui_sub_domain      = var.ui_sub_domain
  api_domain         = format("%s.%s", local.api_sub_domain, local.base_domain)
  ui_domain          = format("%s.%s", local.ui_sub_domain, local.base_domain)
  api_domain_dns     = format("%s.%s", local.api_sub_domain, local.base_dns_name)
  ui_domain_dns      = format("%s.%s", local.ui_sub_domain, local.base_dns_name)

  elastic_sub_domain = coalesce(var.elastic_sub_domain, format("elastic-%s", var.name))
  kibana_sub_domain  = coalesce(var.kibana_sub_domain, format("kibana-%s", var.name))
  grafana_sub_domain = coalesce(var.grafana_sub_domain, format("grafana-%s", var.name))
  elastic_domain     = format("%s.%s", local.elastic_sub_domain, local.base_domain)
  kibana_domain      = format("%s.%s", local.kibana_sub_domain, local.base_domain)
  grafana_domain     = format("%s.%s", local.grafana_sub_domain, local.base_domain)
  elastic_domain_dns = format("%s.%s", local.elastic_sub_domain, local.base_dns_name)
  kibana_domain_dns  = format("%s.%s", local.kibana_sub_domain, local.base_dns_name)
  grafana_domain_dns = format("%s.%s", local.grafana_sub_domain, local.base_dns_name)

  api_instance_machine_type_default = "n1-standard-64"
  api_instance_machine_type         = var.api_instance_machine_type == null ? local.api_instance_machine_type_default : var.api_instance_machine_type
  choose_guest_accelerators = {
    n1 = {
      count = 4
      type  = "nvidia-tesla-t4"
    }
    g2 = {
      count = 4
      type  = "nvidia-l4"
    }
  }
  guest_accelerators = [{
    count = 4
    type  = contains(["n1-", "g2-"], substr(local.api_instance_machine_type, 0, 3)) ? format("%s/zones/%s/acceleratorTypes/%s", local.project, local.zone, local.choose_guest_accelerators[substr(local.api_instance_machine_type, 0, 2)].type) : ""
  }]
  api_instance_data_disk_size_gb_default = 1024
  api_instance_data_disk_size_gb         = var.api_instance_data_disk_size_gb == null ? local.api_instance_data_disk_size_gb_default : var.api_instance_data_disk_size_gb
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
      bucket_name  = ""
      uploader_key = ""
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
  ui_settings            = var.ui_settings == null ? local.ui_settings_defaults : var.ui_settings
  ui_resource_org        = local.ui_settings["resource_org"] == null ? local.ui_settings_defaults["resource_org"] : local.ui_settings["resource_org"]
  ui_resource_team       = local.ui_settings["resource_team"] == null ? local.ui_settings_defaults["resource_team"] : local.ui_settings["resource_team"]
  ui_resource_name       = local.ui_settings["resource_name"] == null ? local.ui_settings_defaults["resource_name"] : local.ui_settings["resource_name"]
  ui_resource_version    = local.ui_settings["resource_version"] == null ? local.ui_settings_defaults["resource_version"] : local.ui_settings["resource_version"]
  ui_resource_url        = format("%s/%s/%s:%s", local.ui_resource_org, local.ui_resource_team, local.ui_resource_name, local.ui_resource_version)
  ui_file                = local.ui_settings["resource_file"] == null ? local.ui_settings_defaults["resource_file"] : local.ui_settings["resource_file"]
  countdown_value        = local.ui_settings["countdown_value"] == null ? local.ui_settings_defaults["countdown_value"] : local.ui_settings["countdown_value"]
  app_title              = local.ui_settings["app_title"] == null ? local.ui_settings_defaults["app_title"] : local.ui_settings["app_title"]
  enable_camera          = local.ui_settings["enable_camera"] == null ? local.ui_settings_defaults["enable_camera"] : local.ui_settings["enable_camera"]
  enable_countdown       = local.ui_settings["enable_countdown"] == null ? local.ui_settings_defaults["enable_countdown"] : local.ui_settings["enable_countdown"]
  application_type       = local.ui_settings["application_type"] == null ? local.ui_settings_defaults["application_type"] : local.ui_settings["application_type"]
  overlay_visible        = local.ui_settings["overlay_visible"] == null ? local.ui_settings_defaults["overlay_visible"] : local.ui_settings["overlay_visible"]
  ui_window_visible      = local.ui_settings["ui_window_visible"] == null ? local.ui_settings_defaults["ui_window_visible"] : local.ui_settings["ui_window_visible"]
  vst_endpoint           = format("https://%s:443", local.api_domain)
  ui_server_endpoint     = format("https://%s:443", local.api_domain)
  websocket_endpoint     = format("wss://%s:443/ws", local.api_domain)
  vst_websocket_endpoint = format("wss://%s:443/vms/ws", local.api_domain)

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

  ops_es_cluster_name = "tokkio-logging-es-cluster"
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

  boot_disk_device_name = "boot"
  data_disk_device_name = "data"
  backend_port_name     = "api-port"
  certificate_config = {
    name = format("%s-cert", local.name)
    domains = [
      local.api_domain,
      local.ui_domain,
      local.elastic_domain,
      local.kibana_domain,
      local.grafana_domain
    ]
  }
  ui_bucket_config = {
    name                     = format("%s-ui", local.name)
    location                 = upper(local.ui_bucket_location.location)
    force_destroy            = true
    website_main_page_suffix = "index.html"
    website_not_found_page   = "index.html"
    region                   = lower(local.ui_bucket_location.region)
    alternate_region         = lower(local.ui_bucket_location.alternate_region)
  }
  ui_backend_config = {
    name             = format("%s-ui", local.name)
    enable_cdn       = var.enable_cdn
    compression_mode = "DISABLED"
  }
  ui_lb_config = {
    name             = format("%s-ui", local.name)
    https_port_range = "443"
    http_port_range  = "80"
  }
  api_instance_image_defaults = "ubuntu-2204-jammy-v20240319"
  api_instance_image          = var.api_instance_image == null ? local.api_instance_image_defaults : var.api_instance_image
  api_instance_config = {
    name       = format("%s-api", local.name)
    network    = local.network
    subnetwork = local.subnetwork
    network_interface = {
      access_configs = []
    }
    tags         = local.instance_tags
    machine_type = local.api_instance_machine_type
    service_account_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
    boot_disk = {
      device_name  = local.boot_disk_device_name
      size_gb      = 50
      source_image = format("projects/ubuntu-os-cloud/global/images/%s", local.api_instance_image)
      type         = "pd-standard"
      auto_delete  = true
    }
    data_disks = [
      {
        device_name = local.data_disk_device_name
        size_gb     = local.api_instance_data_disk_size_gb
        type        = "pd-standard"
        auto_delete = false
      }
    ]
    ssh_public_key = local.ssh_public_key
    ssh_user       = "ubuntu"
    metadata_startup_script = templatefile("${path.module}/user-data/user-data.sh.tpl", {
      name           = local.name
      config_bucket  = local.config_bucket_name
      config_scripts = local.config_scripts
    })
    advanced_machine_features = []
    guest_accelerators        = local.guest_accelerators
    schedulings = [
      {
        on_host_maintenance = "TERMINATE"
      }
    ]
    region           = local.region
    zone             = local.zone
    static_public_ip = false
    group_named_ports = [
      {
        name = local.backend_port_name
        port = 30888
      },
      {
        name = "ops-port"
        port = 31080
      }
    ]
  }
  api_backend_config = {
    name                  = format("%s-api", local.name)
    port_name             = local.backend_port_name
    locality_lb_policy    = "ROUND_ROBIN"
    load_balancing_scheme = "EXTERNAL_MANAGED"
    access_policy = {
      rules = [
        {
          action   = "allow"
          preview  = false
          priority = 999
          matches = [
            {
              versioned_expr = "SRC_IPS_V1"
              configs = [
                {
                  src_ip_ranges = local.user_access_cidrs
                }
              ]
            }
          ]
        },
        {
          action   = "deny(403)"
          preview  = false
          priority = 2147483647
          matches = [
            {
              versioned_expr = "SRC_IPS_V1"
              configs = [
                {
                  src_ip_ranges = ["*"]
                }
              ]
            }
          ]
        }
      ]
    }
    http_health_checks = [
      {
        request_path = "/health"
        port         = 30888
      }
    ]
  }
  api_lb_config = {
    name             = format("%s-api", local.name)
    https_port_range = "443"
    http_port_range  = "80"
  }
  ops_backend_config = {
    name                  = format("%s-ops", local.name)
    port_name             = "ops-port"
    locality_lb_policy    = "ROUND_ROBIN"
    load_balancing_scheme = "EXTERNAL_MANAGED"
    access_policy = {
      rules = [
        {
          action   = "allow"
          preview  = false
          priority = 999
          matches = [
            {
              versioned_expr = "SRC_IPS_V1"
              configs = [
                {
                  src_ip_ranges = local.user_access_cidrs
                }
              ]
            }
          ]
        },
        {
          action   = "deny(403)"
          preview  = false
          priority = 2147483647
          matches = [
            {
              versioned_expr = "SRC_IPS_V1"
              configs = [
                {
                  src_ip_ranges = ["*"]
                }
              ]
            }
          ]
        }
      ]
    }
    http_health_checks = [
      {
        request_path = "/healthz"
        port         = 31080
      }
    ]
    host_rules = [
      {
        hosts        = [local.kibana_domain, local.elastic_domain, local.grafana_domain]
        path_matcher = "path-matcher-1"
    }]
    path_matchers = [
      {
        name = "path-matcher-1"
        path_rules = [
          { paths = ["/"] }
        ]
      }
    ]
  }
}