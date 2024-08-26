
output "public_ip" {
  value = var.include_public_ip ? aws_eip.this[0].public_ip : local.public_ip
}

output "private_ip" {
  value = aws_network_interface.this.private_ip
}

output "security_group_id" {
  value = one(aws_security_group.this.*.id)
}

output "security_group_ids" {
  value = aws_network_interface.this.security_groups
}

output "instance_id" {
  value = local.instance_id
}