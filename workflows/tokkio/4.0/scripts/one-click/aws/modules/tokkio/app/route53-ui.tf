
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
