data "aws_availability_zones" "available" {}

locals {
  vpc_cidr_block = coalesce(var.vpc_cidr_block, "10.0.0.0/16")
  azs = coalescelist(var.availability_zone_names, try(
    slice(sort(data.aws_availability_zones.available.names), 0, 3),
    sort(data.aws_availability_zones.available.names)
  ))
}

module "subnets_cidr" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = local.vpc_cidr_block
  networks = concat(
    [for az in local.azs : {
      name     = format("%s-public", az)
      new_bits = 11
    }],
    [for az in local.azs : {
      name     = format("%s-private", az)
      new_bits = 8
    }]
  )
}

module "vpc" {
  source = "../.."

  virtual_private_cloud = {
    cidr_block           = local.vpc_cidr_block
    enable_dns_hostnames = true
    tags = {
      Name = var.name
    }
  }

  subnets = merge(
    {
      for az in local.azs : format("%s-public", az) => {
        availability_zone       = az
        cidr_block              = module.subnets_cidr.network_cidr_blocks[format("%s-public", az)]
        map_public_ip_on_launch = true
      }
    },
    {
      for az in local.azs : format("%s-private", az) => {
        availability_zone = az
        cidr_block        = module.subnets_cidr.network_cidr_blocks[format("%s-private", az)]
      }
    }
  )

  internet_gateway = {
    enabled = true
  }

  elastic_ips = {
    for az in local.azs : format("%s-nat", az) => {
      vpc = true
    }
  }

  nat_gateways = {
    for az in local.azs : format("%s-public", az) => {
      allocation_id = module.vpc.elastic_ips[format("%s-nat", az)]
      subnet_id     = module.vpc.subnets[format("%s-public", az)]
    }
  }

  route_tables = {
    for az in local.azs : format("%s-private", az) => {
      routes = [
        {
          cidr_block     = "0.0.0.0/0"
          nat_gateway_id = module.vpc.nat_gateways[format("%s-public", az)]
        }
      ]
      subnet_id = module.vpc.subnets[format("%s-private", az)]
    }
  }
}
