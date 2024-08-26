
data "aws_cloudfront_cache_policy" "cache_policy" {
  name = local.cdn_cache_policy
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment  = var.ngc_api_key
  provider = aws.cloudfront
}

resource "aws_cloudfront_distribution" "ui_distribution" {
  origin {
    domain_name         = aws_s3_bucket.ui_bucket.bucket_regional_domain_name
    origin_id           = aws_s3_bucket.ui_bucket.bucket_regional_domain_name
    connection_timeout  = 10
    connection_attempts = 3

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [local.ui_domain]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.ui_bucket.bucket_regional_domain_name
    compress         = true
    cache_policy_id  = data.aws_cloudfront_cache_policy.cache_policy.id

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.base_config.star_cloudfront_certificate.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 10
    response_page_path    = "/index.html"
    response_code         = 200
  }
}