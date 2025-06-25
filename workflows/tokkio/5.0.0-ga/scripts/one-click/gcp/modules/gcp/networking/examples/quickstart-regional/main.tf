locals {
  ip_cidr_range = coalesce(var.ip_cidr_range, "10.0.0.0/16")
}

module "subnets_cidr" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = local.ip_cidr_range
  networks = [
    {
      name     = format("%s-proxy-only", var.name)
      new_bits = 23 - tonumber(split("/", local.ip_cidr_range)[1])
    },
    {
      name     = format("%s-public", var.name)
      new_bits = 2
    },
    {
      name     = format("%s-private", var.name)
      new_bits = 1
    }
  ]
}

module "vpc" {
  source = "../.."

  region = var.region

  virtual_private_clouds = {
    default = {
      name                    = var.name
      auto_create_subnetworks = false
      routing_mode            = "REGIONAL"
    }
  }

  subnets = {
    proxy-only = {
      ip_cidr_range = module.subnets_cidr.network_cidr_blocks[format("%s-proxy-only", var.name)]
      network       = "default"
      purpose       = "REGIONAL_MANAGED_PROXY"
      role          = "ACTIVE"
      name     = format("%s-proxy-only", var.name)
    }
    public = {
      ip_cidr_range = module.subnets_cidr.network_cidr_blocks[format("%s-public", var.name)]
      network       = "default"
      name = format("%s-public", var.name)
    }
    private = {
      ip_cidr_range = module.subnets_cidr.network_cidr_blocks[format("%s-private", var.name)]
      network       = "default"
      name = format("%s-private", var.name)
    }
  }

  routers = {
    default = {
      name = format("%s-router", var.name)
      region = var.region
    }
  }

  ip_addresses = {
    nat = {
      name = format("%s-nat", var.name)
      region = var.region
    }
  }

  nat_gateways = {
    default = {
      name = format("%s-nat", var.name)
      router                             = module.vpc.routers.default.name
      nat_ip_allocate_option             = "MANUAL_ONLY"
      nat_ips                            = [module.vpc.ip_addresses.nat.self_link]
      source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

      subnetwork = [
        {
          name                    = module.vpc.subnets.private.id
          source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
        }
      ]
    }
  }
}
