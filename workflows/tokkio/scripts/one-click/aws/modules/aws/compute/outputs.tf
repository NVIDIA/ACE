output "public_ip" {
  value = one(aws_eip.default[*].public_ip)
}

output "private_ip" {
  value = aws_network_interface.default.private_ip
}

output "security_group_ids" {
  value = aws_network_interface.default.security_groups
}

output "instance_id" {
  value = aws_instance.default.id
}