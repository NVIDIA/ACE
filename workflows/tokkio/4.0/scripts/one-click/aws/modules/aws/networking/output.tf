
output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_subnet_ids" {
  value = aws_subnet.default_private.*.id
}

output "public_subnet_ids" {
  value = aws_subnet.default_public.*.id
}

output "nat_gateway_ip" {
  value = one(aws_nat_gateway.default.*.public_ip)
}