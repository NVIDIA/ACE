resource "aws_route53_record" "cloudfront_dns" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.ui_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.ui_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.ui_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "elastic_dns" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => {
      name  = format("%s-%s-alb", local.name, cluster)
      ports = var.clusters[cluster].ports
    }
    if var.clusters[cluster].private_instance
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.elastic_domain
  type    = "A"

  alias {
    name                   = module.alb[each.key].dns_name
    zone_id                = module.alb[each.key].zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "kibana_dns" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => {
      name  = format("%s-%s-alb", local.name, cluster)
      ports = var.clusters[cluster].ports
    }
    if var.clusters[cluster].private_instance
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.kibana_domain
  type    = "A"

  alias {
    name                   = module.alb[each.key].dns_name
    zone_id                = module.alb[each.key].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "grafana_dns" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => {
      name  = format("%s-%s-alb", local.name, cluster)
      ports = var.clusters[cluster].ports
    }
    if var.clusters[cluster].private_instance
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.grafana_domain
  type    = "A"

  alias {
    name                   = module.alb[each.key].dns_name
    zone_id                = module.alb[each.key].zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "alb_dns" {
  for_each = {
    for cluster in keys(var.clusters) :
    cluster => {
      name  = format("%s-%s-alb", local.name, cluster)
      ports = var.clusters[cluster].ports
    }
    if var.clusters[cluster].private_instance
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name                   = module.alb[each.key].dns_name
    zone_id                = module.alb[each.key].zone_id
    evaluate_target_health = true
  }
}