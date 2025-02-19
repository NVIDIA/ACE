
resource "aws_route53_record" "alb_dns" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}