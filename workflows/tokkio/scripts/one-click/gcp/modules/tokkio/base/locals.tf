
module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = var.network_cidr_range
  networks = [
    {
      name     = local.public_subnet_name
      new_bits = 1
    },
    {
      name     = local.private_subnet_name
      new_bits = 1
    }
  ]
}

locals {
  name = var.name
  all_cidrs = [
    "0.0.0.0/0"
  ]
  gcp_health_cidrs = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]
  public_subnet_name   = "public"
  private_subnet_name  = "private"
  bastion_instance_tag = format("%s-bastion", local.name)
  coturn_instance_tag  = format("%s-coturn", local.name)
  api_instance_tag     = format("%s-api", local.name)
  rp_instance_tag      = format("%s-rp", local.name)
  location             = upper(var.location)
  region               = lower(var.region)
  ui_bucket_location   = var.ui_bucket_location
  zone                 = lower(var.zone)
  networking = {
    name   = local.name
    region = local.region
    subnets = [
      {
        name                     = local.public_subnet_name
        ip_cidr_range            = module.subnet_addrs.network_cidr_blocks[local.public_subnet_name]
        private_ip_google_access = true
        private                  = false
      },
      {
        name                     = local.private_subnet_name
        ip_cidr_range            = module.subnet_addrs.network_cidr_blocks[local.private_subnet_name]
        private_ip_google_access = true
        private                  = true
      }
    ]
    router_bgp = {
      advertise_mode     = "CUSTOM"
      advertised_groups  = []
      asn                = 16550
      keepalive_interval = 20
    }
    firewalls = [
      {
        name     = format("%s-ssh-access-to-bastion", local.name)
        priority = 1000
        allow = [
          {
            protocol = "tcp"
            ports    = [22]
          }
        ]
        nat_source    = false
        source_ranges = var.dev_access_cidrs
        source_tags   = []
        target_tags   = [local.bastion_instance_tag]
      },
      {
        name     = format("%s-ssh-access-via-bastion", local.name)
        priority = 1000
        allow = [
          {
            protocol = "tcp"
            ports    = [22]
          }
        ]
        nat_source    = false
        source_ranges = []
        source_tags   = [local.bastion_instance_tag]
        target_tags   = [local.coturn_instance_tag, local.api_instance_tag, local.rp_instance_tag]
      },
      {
        name     = format("%s-coturn-access", local.name)
        priority = 1000
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
          }
        ]
        nat_source    = true
        source_ranges = var.user_access_cidrs
        source_tags   = []
        target_tags   = [local.coturn_instance_tag]
      },
      {
        name     = format("%s-api-access", local.name)
        priority = 1000
        allow = [
          {
            protocol = "tcp"
            ports    = [30888]
          }
        ]
        nat_source    = false
        source_ranges = local.all_cidrs
        source_tags   = []
        target_tags   = [local.api_instance_tag]
      },
      {
        name     = format("%s-health-port-access", local.name)
        priority = 1000
        allow = [
          {
            protocol = "tcp"
            ports    = [30801]
          }
        ]
        nat_source    = false
        source_ranges = local.gcp_health_cidrs
        source_tags   = []
        target_tags   = [local.api_instance_tag]
      },
      {
        name     = format("%s-ops-access", local.name)
        priority = 1000
        allow = [
          {
            protocol = "tcp"
            ports    = [31080]
          }
        ]
        nat_source    = false
        source_ranges = local.all_cidrs
        source_tags   = []
        target_tags   = [local.api_instance_tag]
      },
      {
        name     = format("%s-rp-port", local.name)
        priority = 1000
        allow = [
          {
            protocol = "tcp"
            ports    = [100]
          }
        ]
        nat_source    = false
        source_ranges = []
        source_tags   = [local.api_instance_tag]
        target_tags   = [local.rp_instance_tag]
      },
      {
        name     = format("%s-rp-udp-streaming", local.name)
        priority = 1000
        allow = [
          {
            protocol = "udp"
            ports    = ["30001-30030"]
          }
        ]
        nat_source    = false
        source_ranges = []
        source_tags   = [local.api_instance_tag, local.rp_instance_tag]
        target_tags   = [local.rp_instance_tag, local.api_instance_tag]
      },
      {
        name     = format("%s-client-streaming-access", local.name)
        priority = 1000
        allow = [
          {
            protocol = "udp"
            ports    = ["10000-20000"]
          }
        ]
        nat_source    = false
        source_ranges = local.all_cidrs
        source_tags   = []
        target_tags   = [local.rp_instance_tag]
      }
    ]
  }
  config_bucket_details = {
    name          = format("%s-config", local.name)
    location      = var.location
    force_destroy = true
  }
  instance_image_defaults = "ubuntu-2204-jammy-v20240319"
  instance_image          = var.bastion_instance_image == null ? local.instance_image_defaults : var.bastion_instance_image
  bastion_config = {
    name       = format("%s-bastion", local.name)
    network    = module.networking.network_name
    subnetwork = module.networking.subnetworks[local.public_subnet_name].name
    network_interface = {
      access_configs = [
        {
          network_tier = "PREMIUM"
        }
      ]
    }
    tags         = [local.bastion_instance_tag]
    machine_type = "e2-medium"
    service_account_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
    boot_disk = {
      device_name  = "boot"
      size_gb      = 50
      source_image = format("projects/ubuntu-os-cloud/global/images/%s", local.instance_image)
      type         = "pd-standard"
      auto_delete  = true
    }
    ssh_public_key   = var.ssh_public_key
    ssh_user         = "ubuntu"
    region           = local.region
    zone             = local.zone
    static_public_ip = true
  }
}