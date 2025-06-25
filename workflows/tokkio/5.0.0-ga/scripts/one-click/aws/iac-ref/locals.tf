data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = var.ami.most_recent
  owners      = var.ami.owners
  dynamic "filter" {
    for_each = var.ami.filters
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

locals {
  name                    = var.name
  bastion_inventory_name  = "bastion"
  master_inventory_name   = "master"
  idle_timeout            = 600
  private_cluster_exists  = anytrue([for cluster in values(var.clusters) : cluster.private_instance])
  availability_zone_names = sort(data.aws_availability_zones.available.names)
  default_az              = element(local.availability_zone_names, 0)
  vpc_id                  = module.networking.vpc
  ssh_user                = "ubuntu"
  ansible_ssh_extra_args  = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  access_ips              = flatten([for cidr in var.user_access_cidrs : [for host_number in range(pow(2, 32 - split("/", cidr)[1])) : cidrhost(cidr, host_number)]])
  access_cidrs = concat(
    [for controller_ip in [var.controller_ip] : format("%s/32", controller_ip) if !contains(local.access_ips, controller_ip)],
    var.user_access_cidrs
  )
  dev_access_ips          = flatten([for cidr in var.dev_access_cidrs : [for host_number in range(pow(2, 32 - split("/", cidr)[1])) : cidrhost(cidr, host_number)]])
  dev_access_cidrs = concat(
    [for controller_ip in [var.controller_ip] : format("%s/32", controller_ip) if !contains(local.dev_access_ips, controller_ip)],
    var.dev_access_cidrs
  )
  node_port_ranges = {
    for cluster in keys(var.clusters) : cluster => [
      for port in values(var.clusters[cluster].ports) : format("%s-%s", port.port, port.port)
    ]
  }
  bastion = {
    ami_id                = data.aws_ami.ubuntu.id
    root_volume_type      = "gp3"
    instance_profile_name = null
    vpc_id                = local.vpc_id
    admin_username        = local.ssh_user
    subnet_id             = module.networking.subnets[format("%s-public", coalesce(var.bastion.az, local.default_az))]
    include_elastic_ip    = true
  }
  cluster = {
    ami_id                = data.aws_ami.ubuntu.id
    root_volume_type      = "gp3"
    instance_profile_name = null
    vpc_id                = local.vpc_id
    admin_username        = local.ssh_user
  }
  turn_server_provider = var.turn_server_provider
  master_sg = ( var.turn_server_provider == "coturn" ? concat([module.coturn_security_group[0].security_group_id]) :
                       var.turn_server_provider == "rp" ? concat([module.rp_udp_streaming_security_group.security_group_id],[module.rp_security_group[0].security_group_id]) :
                       concat([module.app_access_via_bastion_security_group[0].security_group_id,module.bastion_security_group[0].security_group_id],[module.app_access_via_alb_security_group["app"].security_group_id],[module.rp_udp_streaming_security_group.security_group_id]) )
  star_base_domain   = format("*.%s", var.base_domain)
  base_domain = var.base_domain
  grafana_sub_domain  = coalesce(var.grafana_sub_domain, format("%s-grafana", var.name))
  ace_configurator_sub_domain  = coalesce(var.ace_configurator_sub_domain, format("%s-ace-configurator", local.name))
  api_sub_domain      = coalesce(var.api_sub_domain, format("%s-api", local.name))
  ui_sub_domain       = coalesce(var.ui_sub_domain, format("%s-ui", local.name))
  api_domain          = format("%s.%s", local.api_sub_domain, local.base_domain)
  ui_domain           = format("%s.%s", local.ui_sub_domain, local.base_domain)
  grafana_domain      = format("%s.%s", local.grafana_sub_domain, local.base_domain)
  ace_configurator_domain = format("%s.%s", local.ace_configurator_sub_domain, local.base_domain)
  cdn_cache_policy    = var.cdn_cache_enabled ? "Managed-CachingOptimized" : "Managed-CachingDisabled"
  app_tg_name         = format("%s-app-tg", var.name)
  ops_tg_name         = format("%s-ops-tg", var.name)
  ace_configurator_tg_name = format("%s-cfg-tg", var.name)
  data_disk_details = [ for cluster_name, cluster in var.clusters : {
    device_name = "/dev/xvdb"
    volume_size = cluster.master["data_disk_size_gb"]
    volume_type = "gp3"
  } if var.clusters[cluster_name].private_instance ]
  use_reverse_proxy = local.turn_server_provider == "rp" ? true : false
  use_twilio_stun_turn = local.turn_server_provider == "twilio" ? true : false
}