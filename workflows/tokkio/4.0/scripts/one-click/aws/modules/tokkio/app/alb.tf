
module "target_group" {
  source       = "../../aws/target-group"
  name         = local.tg_name
  vpc_id       = var.base_config.networking.vpc_id
  port         = 30888
  protocol     = "HTTP"
  instance_ids = [for instance_suffix in var.instance_suffixes : module.app_instance[instance_suffix].instance_id]
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
  source       = "../../aws/target-group"
  name         = local.ops_tg_name
  vpc_id       = var.base_config.networking.vpc_id
  port         = 31080
  protocol     = "HTTP"
  instance_ids = [for instance_suffix in var.instance_suffixes : module.app_instance[instance_suffix].instance_id]
  health_checks = [{
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 30
    matcher             = "200"
    path                = "/_cluster/health"
    port                = 31080
    protocol            = "HTTP"
    timeout             = 5
  }]
  stickiness = []
}

resource "aws_lb_listener_rule" "ops_rule" {
  listener_arn = module.alb_https_listener.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = module.ops_target_group.arn
  }
  condition {
    host_header {
      values = [
        for sub_domain in [
          local.elastic_sub_domain, local.kibana_sub_domain, local.grafana_sub_domain
        ] : format("%s.%s", sub_domain, local.base_domain)
      ]
    }
  }
}


module "alb" {
  source            = "../../aws/alb"
  name              = local.lb_name
  vpc_id            = var.base_config.networking.vpc_id
  subnet_ids        = var.base_config.networking.public_subnet_ids
  additional_sg_ids = var.base_config.alb_sg_ids
}




module "alb_https_listener" {
  source          = "../../aws/alb-listener"
  lb_arn          = module.alb.arn
  port            = 443
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.base_config.star_alb_certificate.arn
  default_action  = "forward"
  forward_action_configs = {
    target_group_arn = module.target_group.arn
  }
}


module "alb_http_listener" {
  source          = "../../aws/alb-listener"
  lb_arn          = module.alb.arn
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