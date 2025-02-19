
data "aws_route53_zone" "zone" {
  name = local.base_domain
}