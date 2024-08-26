
module "bastion_security_group" {
  source = "../../aws/security-group"
  name   = format("%s-bastion", var.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "ssh access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = var.dev_access_ipv4_cidr_blocks
      ipv6_cidr_blocks = var.dev_access_ipv6_cidr_blocks
      security_groups  = []
      self             = false
    }
  ]
}

module "app_access_via_bastion_security_group" {
  source = "../../aws/security-group"
  name   = format("%s-access-via-bastion", var.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "ssh access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.bastion_security_group.security_group_id]
      self             = false
    }
  ]
}

module "alb_security_group" {
  source = "../../aws/security-group"
  name   = format("%s-alb", var.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "http access"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = var.user_access_ipv4_cidr_blocks
      ipv6_cidr_blocks = var.user_access_ipv6_cidr_blocks
      security_groups  = []
      self             = false
    },
    {
      description      = "https access"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = var.user_access_ipv4_cidr_blocks
      ipv6_cidr_blocks = var.user_access_ipv6_cidr_blocks
      security_groups  = []
      self             = false
    }
  ]
}

module "app_access_via_alb_security_group" {
  source = "../../aws/security-group"
  name   = format("%s-access-via-alb", var.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "ops port access"
      from_port        = 31080
      to_port          = 31080
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.alb_security_group.security_group_id]
      self             = false
    },
    {
      description      = "api port access"
      from_port        = 30888
      to_port          = 30888
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.alb_security_group.security_group_id]
      self             = false
    },
    {
      description      = "health port access"
      from_port        = 30801
      to_port          = 30801
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.alb_security_group.security_group_id]
      self             = false
    }
  ]
}

module "rp_udp_streaming_security_group" {
  source = "../../aws/security-group"
  name   = format("%s-rp-udp-streaming", var.name)
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
  source = "../../aws/security-group"
  name   = format("%s-rp", var.name)
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
      cidr_blocks      = var.user_access_ipv4_cidr_blocks
      ipv6_cidr_blocks = var.user_access_ipv6_cidr_blocks
      security_groups  = []
      self             = false
    },
    {
      description      = "ssh access from bastion"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      security_groups  = [module.bastion_security_group.security_group_id]
      self             = false
    }
  ]
}

module "coturn_security_group" {
  source = "../../aws/security-group"
  name   = format("%s-coturn", var.name)
  vpc_id = local.vpc_id
  ingress_rules = [
    {
      description      = "ssh access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = var.dev_access_ipv4_cidr_blocks
      ipv6_cidr_blocks = var.dev_access_ipv6_cidr_blocks
      security_groups  = []
      self             = false
    },
    {
      description      = "turn server TCP port access"
      from_port        = 3478
      to_port          = 3478
      protocol         = "tcp"
      cidr_blocks      = concat(var.user_access_ipv4_cidr_blocks, [format("%s/32", module.networking.nat_gateway_ip)])
      ipv6_cidr_blocks = var.user_access_ipv6_cidr_blocks
      security_groups  = []
      self             = false
    },
    {
      description      = "turn server UDP port access"
      from_port        = 3478
      to_port          = 3478
      protocol         = "udp"
      cidr_blocks      = concat(var.user_access_ipv4_cidr_blocks, [format("%s/32", module.networking.nat_gateway_ip)])
      ipv6_cidr_blocks = var.user_access_ipv6_cidr_blocks
      security_groups  = []
      self             = false
    },
    {
      description      = "turn server UDP range access"
      from_port        = 49152
      to_port          = 65535
      protocol         = "udp"
      cidr_blocks      = concat(var.user_access_ipv4_cidr_blocks, [format("%s/32", module.networking.nat_gateway_ip)])
      ipv6_cidr_blocks = var.user_access_ipv6_cidr_blocks
      security_groups  = []
      self             = false
    }
  ]
}
