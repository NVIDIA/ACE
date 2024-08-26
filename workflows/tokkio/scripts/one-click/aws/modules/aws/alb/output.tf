
output "security_group_id" {
  value = one(aws_security_group.this.*.id)
}

output "security_group_ids" {
  value = aws_lb.this.security_groups
}

output "arn" {
  value = aws_lb.this.arn
}

output "dns_name" {
  value = aws_lb.this.dns_name
}

output "zone_id" {
  value = aws_lb.this.zone_id
}