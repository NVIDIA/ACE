locals {
  virtual_network_address_space = coalesce(var.virtual_network_address_space, "10.0.0.0/16")
  nat_gateway                   = "nat-gateway"
  public_subnets                = coalescelist(var.public_subnets, ["public-a"])
  private_subnets               = coalescelist(var.private_subnets, ["private-a"])
}

module "subnets_cidr" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = local.virtual_network_address_space
  networks = concat(
    [for subnet in local.public_subnets : {
      name     = subnet
      new_bits = 11
    }],
    [for subnet in local.private_subnets : {
      name     = subnet
      new_bits = 8
    }]
  )
}

module "virtual_network" {
  source = "../.."

  location            = var.location
  resource_group_name = var.resource_group_name

  virtual_network = {
    address_space = [local.virtual_network_address_space]
    name          = var.name
  }

  public_ip_prefixes = zipmap([local.nat_gateway], [for nat_gateway in [local.nat_gateway] : {
    prefix_length = 30
  }])

  public_ips = zipmap([local.nat_gateway], [for nat_gateway in [local.nat_gateway] : {
    allocation_method     = "Static"
    public_ip_prefix_name = nat_gateway
  }])

  nat_gateways = zipmap([local.nat_gateway], [for nat_gateway in [local.nat_gateway] : {
    public_ip_name = nat_gateway
  }])

  route_tables = merge(zipmap(local.private_subnets, [for private_subnet in local.private_subnets : {
    }]), zipmap(local.public_subnets, [for public_subnet in local.public_subnets : {
  }]))

  network_security_groups = {
    private = {
      rules = {}
    }
    public = {
      rules = {}
    }
  }

  subnets = merge(zipmap(local.private_subnets, [for private_subnet in local.private_subnets : {
    address_prefixes             = [module.subnets_cidr.network_cidr_blocks[private_subnet]]
    network_security_group_names = ["private"]
    nat_gateway_name             = local.nat_gateway
    route_table_name             = private_subnet
    delegations                  = try(var.subnet_delegations[private_subnet], null)
    }]), zipmap(local.public_subnets, [for public_subnet in local.public_subnets : {
    address_prefixes             = [module.subnets_cidr.network_cidr_blocks[public_subnet]]
    #nat_gateway_name             = local.nat_gateway
    network_security_group_names = ["public"]
    route_table_name             = public_subnet
    delegations                  = try(var.subnet_delegations[public_subnet], null)
  }]))
}
