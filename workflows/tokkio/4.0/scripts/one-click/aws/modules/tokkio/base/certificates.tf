
module "star_alb_certificate" {
  source           = "../../aws/acm-certificate"
  domain_name      = local.star_base_domain
  hosted_zone_name = var.base_domain
}

module "star_cloudfront_certificate" {
  source           = "../../aws/acm-certificate"
  domain_name      = local.star_base_domain
  hosted_zone_name = var.base_domain
  providers = {
    aws = aws.cloudfront
  }
}