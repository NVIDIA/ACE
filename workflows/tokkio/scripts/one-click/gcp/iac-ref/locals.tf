data "google_compute_zones" "available" {}

locals {
  name                   = var.name
  region                 = var.region
  bastion_inventory_name = "bastion"
  master_inventory_name  = "master"
  private_cluster_exists = anytrue([for cluster in values(var.clusters) : cluster.private_instance])
  zone_names             = sort(data.google_compute_zones.available.names)
  default_zone           = element(local.zone_names, 0)
  network_id             = module.networking.virtual_private_cloud["id"]
  network_name           = module.networking.virtual_private_cloud["name"]
  network_self_link      = module.networking.virtual_private_cloud["self_link"]
  ssh_user               = "ubuntu"
  ansible_ssh_extra_args = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  access_ips             = flatten([for cidr in var.user_access_cidrs : [for host_number in range(pow(2, 32 - split("/", cidr)[1])) : cidrhost(cidr, host_number)]])
  gcp_health_check_cidrs = ["130.211.0.0/22", "35.191.0.0/16"]
  all_cidrs = ["0.0.0.0/0"]
  proxy_only_subnet_cidr = module.networking.subnets["proxy-only"]["ip_cidr_range"]
  access_cidrs = concat(
    [for controller_ip in [var.controller_ip] : format("%s/32", controller_ip) if !contains(local.access_ips, controller_ip)],
    var.user_access_cidrs
  )
  dev_access_ips             = flatten([for cidr in var.dev_access_cidrs : [for host_number in range(pow(2, 32 - split("/", cidr)[1])) : cidrhost(cidr, host_number)]])
  dev_access_cidrs = concat(
    [for controller_ip in [var.controller_ip] : format("%s/32", controller_ip) if !contains(local.dev_access_ips, controller_ip)],
    var.dev_access_cidrs
  )
  node_port_ranges = {
    for cluster in keys(var.clusters) : cluster => [
      for port in values(var.clusters[cluster].ports) : format("%s-%s", port.port, port.port)
    ]
  }
  bastion_hosts = local.private_cluster_exists ? ["bastion"] : []
  turn_server_provider = var.turn_server_provider
  common_tag = "internal"
  firewall_rules = merge({
    for bastion_host in local.bastion_hosts :
    format("%s-access-ssh-on-%s", local.name, bastion_host) => {
      description   = "ssh access to bastion"
      direction     = "INGRESS"
      network       = local.network_self_link
      source_ranges = local.dev_access_cidrs
      target_tags   = [format("%s-bastion", local.name)]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
    }
    },

    {
      for k, v in var.clusters :
      format("%s-ssh-access-via-bastion-%s", local.name, k) => {
        description   = format("ssh access via bastion %s", k)
        direction     = "INGRESS"
        network       = local.network_self_link
        source_ranges = null
        source_tags   = [format("%s-bastion", local.name)]
        target_tags   = [format("%s-%s", local.name, k)]
        allow = [
          {
            protocol = "tcp"
            ports    = ["22"]
          }
        ]
      } if v.private_instance
    },

    {
      for k, v in var.clusters :
      format("%s-api-access-%s", local.name, k) => {
        description = format("app api port access %s", k)
        direction   = "INGRESS"
        network     = local.network_self_link
        source_ranges = local.access_cidrs
        target_tags = [format("%s-%s", local.name, k)]
        allow = [
          {
            protocol = "tcp"
            ports    = [30888]
          }
        ]
      } if v.private_instance
    },

    {
      for k, v in var.clusters :
      format("%s-health-port-access-%s", local.name, k) => {
        description   = format("health port access %s", k)
        direction     = "INGRESS"
        network       = local.network_self_link
        source_ranges = local.gcp_health_check_cidrs
        source_tags   = []
        target_tags   = [format("%s-%s", local.name, k)]
        allow = [
          {
            protocol = "tcp"
            ports    = [30801]
          },
          {
            protocol = "tcp"
            ports    = [31080]
          },
          {
            protocol = "tcp"
            ports    = [30888]
          },
        ]
      } if v.private_instance
    },

    {
      for k, v in var.clusters :
      format("%s-ops-access-%s", local.name, k) => {
        description   = format("ops port access %s", k)
        direction     = "INGRESS"
        network       = local.network_self_link
        source_ranges = local.access_cidrs
        source_tags   = []
        target_tags   = [format("%s-%s", local.name, k)]
        allow = [
          {
            protocol = "tcp"
            ports    = [31080]
          }
        ]
      } if v.private_instance
    },

    {
      for k, v in var.clusters :
      format("%s-coturn-access-%s", local.name, k) => {
        description   = format("coturn access to %s from users", k)
        direction     = "INGRESS"
        network       = local.network_self_link
        source_ranges = concat(local.access_cidrs, [format("%s/32", module.networking.nat_gateways_ip)]) #concat(each.value["source_ranges"], [format("%s/32", google_compute_address.nat.address)]) : each.value["source_ranges"]
        source_tags   = []
        target_tags   = [format("%s-%s", local.name, k)]
        allow = [
          {
            protocol = "tcp"
            ports    = [3478]
          },
          {
            protocol = "udp"
            ports    = [3478]
          },
          {
            protocol = "udp"
            ports    = ["49152-65535"]
          },
        ]
      } if !v.private_instance && local.turn_server_provider == "coturn"
    },

    {
      for k, v in var.clusters :
      format("%s-coturn-ssh-access-%s", local.name, k) => {
        description   = format("coturn ssh access to %s from users", k)
        direction     = "INGRESS"
        network       = local.network_self_link
        source_ranges = concat(local.dev_access_cidrs) #concat(each.value["source_ranges"], [format("%s/32", google_compute_address.nat.address)]) : each.value["source_ranges"]
        source_tags   = []
        target_tags   = [format("%s-%s", local.name, k)]
        allow = [
          {
            protocol = "tcp"
            ports    = [22]
          }
        ]
      } if !v.private_instance && local.turn_server_provider == "coturn"
    },

    {
      for k, v in var.clusters :
      format("%s-rp-ssh-%s", local.name, k) => {
        description   = format("rp ssh %s", k)
        direction     = "INGRESS"
        network       = local.network_self_link
        source_ranges = local.dev_access_cidrs
        source_tags   = []
        target_tags   = [format("%s-%s", local.name, k)]
        allow = [
          {
            protocol = "tcp"
            ports    = [22]
          }
        ]
      } if !v.private_instance && local.turn_server_provider == "rp"
    },

    {
      for k, v in var.clusters :
      format("%s-rp-client-streaming-access-%s", local.name, k) => {
        description   = format("ssh access to %s", k)
        direction     = "INGRESS"
        network       = local.network_self_link
        source_ranges = local.access_cidrs
        source_tags   = []
        target_tags   = [format("%s-%s", local.name, k)]
        allow = [
          {
            protocol = "udp"
            ports    = ["10000-20000"]
          }
        ]
      } if !v.private_instance && local.turn_server_provider == "rp"
    },
    {
      for k, v in var.clusters :
      format("%s-inter-cluster-access-on-%s", local.name, k) => {
        description = format("all access to %s", k)
        direction   = "INGRESS"
        network     = local.network_self_link
        source_tags = [local.common_tag]
        target_tags = [local.common_tag]
        allow = [
          {
            protocol = "all"
          }
        ]
      } if !v.private_instance
    }
  )
  bastion = {
    ssh_public_key = var.ssh_public_key
    ssh_user       = local.ssh_user
    compute_addresses = {
      public = {
        name = format("%s-bastion", local.name)
      }
    }
    instance = {
      name = format("%s-bastion", local.name)
      tags = [
        format("%s-bastion", local.name)
      ]
      machine_type = var.bastion.type
      zone         = coalesce(var.bastion.zone, local.default_zone)
      network_interface = [
        {
          network    = local.network_name
          subnetwork = module.networking.subnets["public"]["name"]
          access_config = [
            {
              network_tier = "PREMIUM"
              nat_ip       = "public"
            }
          ]
        }
      ]
      boot_disk = {
        initialize_params = {
          device_name = "boot"
          size        = var.bastion.disk_size_gb
          image       = format("projects/ubuntu-os-cloud/global/images/%s", var.machine_image)
          type        = "pd-standard"
        }
      }
      metadata = {
        ssh-keys = join("\n", [
          format("%s:%s %s", local.ssh_user, join(" ", slice(split(" ", var.ssh_public_key), 0, 2)), local.ssh_user)
        ])
      }
    }
  }
  masters = {
    for k, cluster in var.clusters :
    k => {
      ssh_public_key = var.ssh_public_key
      ssh_user       = local.ssh_user
      compute_addresses = cluster.private_instance ? {} : {
        public = {
          name = format("%s-%s-master", local.name, k)
        }
      }
      instance = {
        name = format("%s-%s-master", local.name, k)
        tags = [
          format("%s-%s", local.name, k), local.common_tag
        ]
        machine_type      = cluster.master.type
        guest_accelerator = cluster.master.guest_accelerators
        zone              = coalesce(cluster.zone, local.default_zone)
        network_interface = [
          {
            network    = local.network_name
            subnetwork = cluster.private_instance ? module.networking.subnets["private"]["name"] : module.networking.subnets["public"]["name"]
            access_config = cluster.private_instance ? [] : [
              {
                network_tier = "PREMIUM"
                nat_ip       =  "public"
              }
            ]
          }
        ]
        boot_disk = {
          initialize_params = {
            device_name = "boot"
            size        = cluster.master.disk_size_gb
            image       = format("projects/ubuntu-os-cloud/global/images/%s", var.machine_image)
            type        = "pd-standard"
          }
        }
        data_disks = cluster.private_instance ? [{
            device_name = "data"
            size_gb     = cluster.master.data_disk_size_gb
            type        = "pd-standard"
            auto_delete = false
          }]: null
        metadata = {
          ssh-keys = join("\n", [
            format("%s:%s %s", local.ssh_user, join(" ", slice(split(" ", var.ssh_public_key), 0, 2)), local.ssh_user)
          ])
        }
        scheduling = cluster.master.guest_accelerators != null && length(cluster.master.guest_accelerators) > 0 ? {
          on_host_maintenance = "TERMINATE"
        } : null
      service_account = cluster.private_instance ? { 
        scopes = [
                "https://www.googleapis.com/auth/devstorage.read_write",
                "https://www.googleapis.com/auth/devstorage.read_only",
                "https://www.googleapis.com/auth/logging.write",
                "https://www.googleapis.com/auth/monitoring.write",
                "https://www.googleapis.com/auth/service.management.readonly",
                "https://www.googleapis.com/auth/servicecontrol",
                "https://www.googleapis.com/auth/trace.append"
              ]
        email     = google_service_account.api_instance_service_account["app"].email
         } : null
      }
    }
  }
  nodes = merge([
    for k, cluster in var.clusters : {
      for n, node in cluster.nodes :
      format("%s-%s", k, n) => {
        ssh_public_key = var.ssh_public_key
        ssh_user       = local.ssh_user
        compute_addresses = {
          public = {
            name = format("%s-%s-%s", local.name, k, n)
          }
        }
        instance = {
          name = format("%s-%s-%s", local.name, k, n)
          tags = [
            format("%s-%s", local.name, k)
          ]
          machine_type      = node.type
          guest_accelerator = node.guest_accelerators
          zone              = coalesce(cluster.zone, local.default_zone)
          network_interface = [
            {
              network    = local.network_name
              subnetwork = module.networking.subnets["public"]["name"]
              access_config = [
                {
                  network_tier = "PREMIUM"
                  nat_ip       = cluster.private_instance ? "public" : null
                }
              ]
            }
          ]
          boot_disk = {
            initialize_params = {
              device_name = "boot"
              size        = node.disk_size_gb
              image       = format("projects/ubuntu-os-cloud/global/images/%s", var.machine_image)
              type        = "pd-standard"
            }
          }
          metadata = {
            ssh-keys = join("\n", [
              format("%s:%s %s", local.ssh_user, join(" ", slice(split(" ", var.ssh_public_key), 0, 2)), local.ssh_user)
            ])
          }
          scheduling = node.guest_accelerators != null && length(node.guest_accelerators) > 0 ? {
            on_host_maintenance = "TERMINATE"
          } : null
        }
      }
    }
  ]...)
  backend_port_name     = "api-port"
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
                  src_ip_ranges = local.access_cidrs
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
                  src_ip_ranges = local.access_cidrs
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
  }
  api_lb_config = {
    name             = format("%s-api", local.name)
    https_port_range = "443"
    http_port_range  = "80"
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
  dns_zone_name      = var.dns_zone_name
  base_dns_name      = data.google_dns_managed_zone.dns_zone.dns_name
  base_domain        = trimsuffix(local.base_dns_name, ".")
  api_sub_domain     = coalesce(var.api_sub_domain, format("%s-api", var.name))
  ui_sub_domain      = coalesce(var.ui_sub_domain, format("%s-ui", var.name))
  elastic_sub_domain = coalesce(var.elastic_sub_domain, format("%s-elastic", var.name))
  kibana_sub_domain  = coalesce(var.kibana_sub_domain, format("%s-kibana", var.name))
  grafana_sub_domain = coalesce(var.grafana_sub_domain, format("%s-grafana", var.name))
  api_domain         = format("%s.%s", local.api_sub_domain, local.base_domain)
  ui_domain          = format("%s.%s", local.ui_sub_domain, local.base_domain)
  elastic_domain     = format("%s.%s", local.elastic_sub_domain, local.base_domain)
  kibana_domain      = format("%s.%s", local.kibana_sub_domain, local.base_domain)
  grafana_domain     = format("%s.%s", local.grafana_sub_domain, local.base_domain)
  api_domain_dns     = format("%s.%s", local.api_sub_domain, local.base_dns_name)
  ui_domain_dns      = format("%s.%s", local.ui_sub_domain, local.base_dns_name)
  elastic_domain_dns = format("%s.%s", local.elastic_sub_domain, local.base_dns_name)
  kibana_domain_dns  = format("%s.%s", local.kibana_sub_domain, local.base_dns_name)
  grafana_domain_dns = format("%s.%s", local.grafana_sub_domain, local.base_dns_name)
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
  ui_bucket_location = var.ui_bucket_location
  ui_bucket_config = {
    location                 = upper(local.ui_bucket_location.location)
    force_destroy            = true
    website_main_page_suffix = "index.html"
    website_not_found_page   = "index.html"
    region                   = lower(local.ui_bucket_location.region)
    alternate_region         = lower(local.ui_bucket_location.alternate_region)
  }
  ui_backend_config = {
    enable_cdn       = var.enable_cdn
    compression_mode = "DISABLED"
  }
  ui_lb_config = {
    https_port_range = "443"
    http_port_range  = "80"
  }
  use_reverse_proxy = local.turn_server_provider == "rp" ? true : false
  use_twilio_stun_turn = local.turn_server_provider == "twilio" ? true : false
}