module "networking" {
  source                  = "../modules/aws/networking/examples/quickstart"
  name                    = local.name
  availability_zone_names = local.availability_zone_names
}

module "bastion_security_group" {
  count  = local.private_cluster_exists ? 1 : 0
  source = "../modules/aws/security-group"
  name   = format("%s-bastion", local.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "ssh access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = local.dev_access_cidrs
      ipv6_cidr_blocks = [] #local.access_cidrs
      security_groups  = []
      self             = false
    }
  ]
}

module "app_access_via_bastion_security_group" {
  count  = local.private_cluster_exists ? 1 : 0
  source = "../modules/aws/security-group"
  name   = format("%s-access-via-bastion", local.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "ssh access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.bastion_security_group[0].security_group_id]
      self             = false
    }
  ]
}

module "alb_security_group" {
 for_each = {
    for k, v in var.clusters :
    k => v
    if v.private_instance
  }
  source = "../modules/aws/security-group"
  name   = format("%s-%s-alb", local.name, each.key)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "http access"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = local.access_cidrs
      ipv6_cidr_blocks = [] #local.access_cidrs
      security_groups  = []
      self             = false
    },
    {
      description      = "https access"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = local.access_cidrs
      ipv6_cidr_blocks = [] #local.access_cidrs
      security_groups  = []
      self             = false
    }
  ]
}

module "app_access_via_alb_security_group" {
 for_each = {
    for k, v in var.clusters :
    k => v
    if v.private_instance
  }
  source = "../modules/aws/security-group"
  name   = format("%s-%s-access-via-alb", local.name, each.key)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "ace configurator port access"
      from_port        = 30180
      to_port          = 30180
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.alb_security_group[each.key].security_group_id]
      self             = false
    },
    {
      description      = "ops port access"
      from_port        = 32300
      to_port          = 32300
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.alb_security_group[each.key].security_group_id]
      self             = false
    },
    {
      description      = "api port access"
      from_port        = 30888
      to_port          = 30888
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.alb_security_group[each.key].security_group_id]
      self             = false
    },
    {
      description      = "health port access"
      from_port        = 30801
      to_port          = 30801
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.alb_security_group[each.key].security_group_id]
      self             = false
    }
  ]
}

module "rp_udp_streaming_security_group" {
  #count  = local.turn_server_provider == "rp" ? 1 : 0
  source = "../modules/aws/security-group"
  name   = format("%s-rp-udp-streaming", local.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "udp streaming access"
      from_port        = 30001
      to_port          = 30030
      protocol         = "udp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = []
      self             = true
    }
  ]
}

module "rp_security_group" {
  count  = local.turn_server_provider == "rp" ? 1 : 0
  source = "../modules/aws/security-group"
  name   = format("%s-rp", local.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "rp port negotiation access"
      from_port        = 100
      to_port          = 100
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.rp_udp_streaming_security_group.security_group_id]
      self             = false
    },
    {
      description      = "client udp streaming access"
      from_port        = 10000
      to_port          = 20000
      protocol         = "udp"
      cidr_blocks      = local.access_cidrs
      ipv6_cidr_blocks = []
      security_groups  = []
      self             = false
    },
    {
      description      = "ssh access from bastion"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = local.dev_access_cidrs
      ipv6_cidr_blocks = []
      security_groups  = [module.bastion_security_group[0].security_group_id]
      self             = false
    }
  ]
}

module "coturn_security_group" {
  count  = local.turn_server_provider == "coturn" ? 1 : 0
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


module "bastion" {
  count                 = local.private_cluster_exists ? 1 : 0
  source                = "../modules/aws/compute"
  instance_name         = format("%s-bastion", local.name)
  instance_type         = var.bastion.type
  ami_id                = local.bastion.ami_id
  public_key            = var.ssh_public_key
  root_volume_type      = local.bastion.root_volume_type
  root_volume_size      = var.bastion.disk_size_gb
  instance_profile_name = local.bastion.instance_profile_name
  vpc_id                = local.bastion.vpc_id
  subnet_id             = local.bastion.subnet_id
  security_groups       = [module.bastion_security_group[count.index].security_group_id]
  include_elastic_ip    = local.bastion.include_elastic_ip
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
  security_groups       = each.value["private_instance"] ? concat([module.app_access_via_bastion_security_group[0].security_group_id,module.app_access_via_alb_security_group[each.key].security_group_id],[module.rp_udp_streaming_security_group.security_group_id]) : local.master_sg
  include_elastic_ip    = !each.value["private_instance"]
  ebs_block_devices = each.value["private_instance"] ? local.data_disk_details : [] 
}

module "node" {
  for_each = merge([for cluster in keys(var.clusters) : { for node in keys(var.clusters[cluster].nodes) : format("%s-%s", cluster, node) => merge(var.clusters[cluster].nodes[node], {
    cluster          = cluster
    private_instance = var.clusters[cluster].private_instance
  }) }]...)
  source                = "../modules/aws/compute"
  instance_name         = format("%s-%s", local.name, each.key)
  instance_type         = each.value["type"]
  ami_id                = local.cluster.ami_id
  public_key            = var.ssh_public_key
  root_volume_type      = local.cluster.root_volume_type
  root_volume_size      = each.value["disk_size_gb"]
  instance_profile_name = local.cluster.instance_profile_name
  vpc_id                = local.cluster.vpc_id
  subnet_id             = each.value["private_instance"] ? module.networking.subnets[format("%s-private", coalesce(each.value["az"], local.default_az))] : module.networking.subnets[format("%s-public", coalesce(each.value["az"], local.default_az))]
  security_groups       = [] #local.turn_server_provider == "rp" ? concat(local.master_sg, [module.rp_udp_streaming_security_group[0].security_group_id]) : local.master_sg
  include_elastic_ip    = !each.value["private_instance"]
}


module "star_alb_certificate" {
  source           = "../modules/aws/acm-certificate"
  domain_name      = local.star_base_domain
  hosted_zone_name = var.base_domain
}

module "star_cloudfront_certificate" {
  source           = "../modules/aws/acm-certificate"
  domain_name      = local.star_base_domain
  hosted_zone_name = var.base_domain
  providers = {
    aws = aws.cloudfront
  }
}

module "target_group" {
  for_each = {
      for k, v in var.clusters :
      k => v
      if v.private_instance
    }
  source       = "../modules/aws/target-group"
  name         = local.app_tg_name
  vpc_id       = local.vpc_id
  port         = 30888
  protocol     = "HTTP"
  instance_ids = [module.master[each.key].instance_id]
  health_checks = [{
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = 30801
    protocol            = "HTTP"
    timeout             = 5
  }]
  stickiness = [{
    cookie_duration = 604800
    type            = "app_cookie"
    cookie_name     = "Session"
    enabled         = true
  }]
}

module "ops_target_group" {
    for_each = {
        for k, v in var.clusters :
        k => v
        if v.private_instance
      }
  source       = "../modules/aws/target-group"
  name         = local.ops_tg_name
  vpc_id       = local.vpc_id
  port         = 32300
  protocol     = "HTTP"
  instance_ids = [module.master[each.key].instance_id]
  health_checks = [{
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = 32300
    protocol            = "HTTP"
    timeout             = 5
  }]
  stickiness = []
}

module "ace_cfg_target_group" {
    for_each = {
        for k, v in var.clusters :
        k => v
        if v.private_instance
      }
  source       = "../modules/aws/target-group"
  name         = local.ace_configurator_tg_name
  vpc_id       = local.vpc_id
  port         = 30180
  protocol     = "HTTP"
  instance_ids = [module.master[each.key].instance_id]
  health_checks = [{
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/v1/ready"
    port                = 30180
    protocol            = "HTTP"
    timeout             = 5
  }]
  stickiness = []
}

module "alb" {
  for_each = {
      for k, v in var.clusters :
      k => v
      if v.private_instance
    }
  source            = "../modules/aws/alb"
  name              = format("%s-lb", local.name)
  vpc_id            = local.vpc_id
  subnet_ids        = [for az in local.availability_zone_names : module.networking.subnets[format("%s-public", az)]]
  additional_sg_ids = [module.alb_security_group[each.key].security_group_id]
  idle_timeout      = local.idle_timeout
}

module "alb_https_listener" {
  for_each = {
      for k, v in var.clusters :
      k => v
      if v.private_instance
    }
  source          = "../modules/aws/alb-listener"
  lb_arn          = module.alb[each.key].arn
  port            = 443
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn = module.star_alb_certificate.arn
  default_action  = "forward"
  forward_action_configs = {
    target_group_arn = module.target_group[each.key].arn
  }
}

module "alb_http_listener" {
  for_each = {
      for k, v in var.clusters :
      k => v
      if v.private_instance
    }
  source          = "../modules/aws/alb-listener"
  lb_arn          = module.alb[each.key].arn
  port            = 80
  protocol        = "HTTP"
  ssl_policy      = null
  certificate_arn = null
  default_action  = "redirect"
  redirect_action_configs = {
    port        = 443
    protocol    = "HTTPS"
    status_code = "HTTP_301"
  }
}

resource "aws_lb_listener_rule" "ops_rule" {
  for_each = {
      for k, v in var.clusters :
      k => v
      if v.private_instance
    } 
  listener_arn = module.alb_https_listener[each.key].arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = module.ops_target_group[each.key].arn
  }
  condition {
    host_header {
      values = [
        for sub_domain in [
          local.grafana_sub_domain
        ] : format("%s.%s", sub_domain, local.base_domain)
      ]
    }
  }
}

resource "aws_lb_listener_rule" "ace_configurator_rule" {
  for_each = {
      for k, v in var.clusters :
      k => v
      if v.private_instance
    } 
  listener_arn = module.alb_https_listener[each.key].arn
  priority     = 101
  action {
    type             = "forward"
    target_group_arn = module.ace_cfg_target_group[each.key].arn
  }
  condition {
    host_header {
      values = [
        for sub_domain in [
          local.ace_configurator_sub_domain
        ] : format("%s.%s", sub_domain, local.base_domain)
      ]
    }
  }
}
