data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = var.ami.most_recent
  owners      = var.ami.owners
  dynamic "filter" {
    for_each = var.ami.filters != null ? var.ami.filters : {}
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

locals {
  name                    = var.name
  vpc_id                  = module.networking.vpc
  turn_server_provider    = var.turn_server_provider
  master_inventory_name   = "master"
  ssh_user                = "ubuntu"
  ansible_ssh_extra_args  = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  availability_zone_names = sort(data.aws_availability_zones.available.names)
  default_az              = element(local.availability_zone_names, 0)

  node_port_ranges = {
    for cluster in keys(var.clusters) : cluster => [
      for port in values(var.clusters[cluster].ports) : format("%s-%s", port.port, port.port)
    ]
  }

  cluster = {
    ami_id                = data.aws_ami.ubuntu.id
    root_volume_type      = "gp3"
    instance_profile_name = null
    vpc_id                = local.vpc_id
    admin_username        = local.ssh_user
  }
  data_disk_details = [for cluster_name, cluster in var.clusters : {
    device_name = "/dev/xvdb"
    volume_size = cluster.master["data_disk_size_gb"]
    volume_type = "gp3"
  }]

  master_sg = [module.lite_instance_security_group.security_group_id]

  access_ips = flatten([for cidr in var.user_access_cidrs : [for host_number in range(pow(2, 32 - split("/", cidr)[1])) : cidrhost(cidr, host_number)]])
  access_cidrs = concat(
    [for controller_ip in [var.controller_ip] : format("%s/32", controller_ip) if !contains(local.access_ips, controller_ip)],
    var.user_access_cidrs
  )

  dev_access_ips = flatten([for cidr in var.dev_access_cidrs : [for host_number in range(pow(2, 32 - split("/", cidr)[1])) : cidrhost(cidr, host_number)]])
  dev_access_cidrs = concat(
    [for controller_ip in [var.controller_ip] : format("%s/32", controller_ip) if !contains(local.dev_access_ips, controller_ip)],
    var.dev_access_cidrs
  )
  use_twilio_stun_turn = local.turn_server_provider == "twilio" ? true : false
}