module "networking" {
  source                  = "../modules/aws/networking/examples/quickstart"
  name                    = local.name
  availability_zone_names = local.availability_zone_names
}

module "lite_instance_security_group" {
  source = "../modules/aws/security-group"
  name   = format("%s-coturn", local.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "ssh access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = local.dev_access_cidrs
      ipv6_cidr_blocks = []
      security_groups  = []
      self             = false
    },
    {
      description      = "turn server TCP port access"
      from_port        = 3478
      to_port          = 3478
      protocol         = "tcp"
      cidr_blocks      = concat(local.access_cidrs, [for az, ip in module.networking.nat_gateways_public_ip : "${ip}/32"])
      ipv6_cidr_blocks = []
      security_groups  = []
      self             = false
    },
    {
      description      = "turn server UDP port access"
      from_port        = 3478
      to_port          = 3478
      protocol         = "udp"
      cidr_blocks      = concat(local.access_cidrs, [for az, ip in module.networking.nat_gateways_public_ip : "${ip}/32"])
      ipv6_cidr_blocks = []
      security_groups  = []
      self             = false
    },
    {
      description      = "turn server UDP range access"
      from_port        = 49152
      to_port          = 65535
      protocol         = "udp"
      cidr_blocks      = concat(local.access_cidrs, [for az, ip in module.networking.nat_gateways_public_ip : "${ip}/32"])
      ipv6_cidr_blocks = []
      security_groups  = []
      self             = false
    }
  ]
}

module "master" {
  for_each = { for cluster in keys(var.clusters) : cluster => merge(var.clusters[cluster].master, {
    private_instance = var.clusters[cluster].private_instance
  }) }
  source                = "../modules/aws/compute"
  instance_name         = format("%s-%s-master", local.name, each.key)
  instance_type         = each.value["type"]
  ami_id                = local.cluster.ami_id
  public_key            = var.ssh_public_key
  root_volume_type      = local.cluster.root_volume_type
  root_volume_size      = each.value["disk_size_gb"]
  instance_profile_name = aws_iam_instance_profile.instance.name
  vpc_id                = local.cluster.vpc_id
  subnet_id             = each.value["private_instance"] ? module.networking.subnets[format("%s-private", coalesce(each.value["az"], local.default_az))] : module.networking.subnets[format("%s-public", coalesce(each.value["az"], local.default_az))]
  security_groups       = concat(local.master_sg, [module.cluster_sg[each.key].security_group_id])
  include_elastic_ip    = !each.value["private_instance"]
  ebs_block_devices     = local.data_disk_details
}

module "cluster_sg" {
  for_each = { for cluster in keys(var.clusters) : cluster => merge(var.clusters[cluster].master, {
    private_instance = var.clusters[cluster].private_instance
  }) }
  source = "../modules/aws/security-group"
  name   = format("%s-%s", local.name, each.key)
  vpc_id = local.vpc_id
  ingress_rules = concat(
    flatten([
      for node_port_range in local.node_port_ranges[each.key] : [
        for access_cidr in local.access_cidrs :
        {
          description      = format("node port access from %s", access_cidr)
          from_port        = element(split("-", node_port_range), 0)
          to_port          = element(split("-", node_port_range), 1)
          protocol         = "tcp"
          cidr_blocks      = [access_cidr]
          ipv6_cidr_blocks = []
          security_groups  = []
          self             = false
        }
      ] if !each.value["private_instance"]
    ])
  )
}