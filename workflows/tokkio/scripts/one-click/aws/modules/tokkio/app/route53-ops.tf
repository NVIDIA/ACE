
resource "aws_route53_record" "elastic_dns" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.elastic_domain
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "kibana_dns" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.kibana_domain
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "grafana_dns" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.grafana_domain
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = false
  }
}