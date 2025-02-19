
output "networking" {
  value = module.networking
}

output "keypair" {
  value = module.key_pair
}

output "bastion_instance" {
  value = module.bastion_instance
}

output "app_sg_ids" {
  value = [module.app_access_via_bastion_security_group.security_group_id, module.app_access_via_alb_security_group.security_group_id, module.rp_udp_streaming_security_group.security_group_id]
}

output "rp_sg_ids" {
  value = [module.rp_udp_streaming_security_group.security_group_id, module.rp_security_group.security_group_id]
}

output "alb_sg_ids" {
  value = [module.alb_security_group.security_group_id]
}

output "coturn_sg_ids" {
  value = [module.coturn_security_group.security_group_id]
}

output "config_bucket" {
  value = aws_s3_bucket.config_bucket.id
}

output "config_access_policy_arn" {
  value = aws_iam_policy.config_bucket_access.arn
}

output "base_domain" {
  value = var.base_domain
}

output "star_alb_certificate" {
  value = module.star_alb_certificate
}

output "star_cloudfront_certificate" {
  value = module.star_cloudfront_certificate
}