
data "aws_availability_zones" "available" {}

locals {
  availability_zones = data.aws_availability_zones.available.names
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = merge({
    Name = var.vpc_name
  }, var.additional_tags)
}

resource "aws_internet_gateway" "default" {
  count  = length(var.public_subnet_names) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = merge({
    Name = var.vpc_name
  }, var.additional_tags)
}

resource "aws_subnet" "default_public" {
  count                   = length(var.public_subnet_names)
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.availability_zones[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 2, count.index)
  map_public_ip_on_launch = true
  tags = merge({
    Name = var.public_subnet_names[count.index]
  }, var.additional_tags)
}

resource "aws_subnet" "default_private" {
  count             = length(var.private_subnet_names)
  vpc_id            = aws_vpc.this.id
  availability_zone = local.availability_zones[count.index]
  cidr_block        = cidrsubnet(var.cidr_block, 2, count.index + length(var.private_subnet_names))
  tags = merge({
    Name = var.private_subnet_names[count.index]
  }, var.additional_tags)
}

resource "aws_eip" "default" {
  count = length(var.private_subnet_names) > 0 ? 1 : 0
  vpc   = true
  tags = merge({
    Name = var.vpc_name
  }, var.additional_tags)
}

resource "aws_nat_gateway" "default" {
  count         = length(var.private_subnet_names) > 0 ? 1 : 0
  allocation_id = aws_eip.default[0].id
  subnet_id     = element(aws_subnet.default_public.*.id, count.index)
  tags = merge({
    Name = var.vpc_name
  }, var.additional_tags)
}

resource "aws_route_table" "default_public" {
  count  = length(var.public_subnet_names) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default[0].id
  }
  tags = merge({
    Name = var.vpc_name
  }, var.additional_tags)
}

resource "aws_route_table_association" "default_public" {
  count          = length(var.public_subnet_names)
  route_table_id = aws_route_table.default_public[0].id
  subnet_id      = aws_subnet.default_public[count.index].id
}

resource "aws_route_table" "default_private" {
  count  = length(var.private_subnet_names) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.default[0].id
  }
  tags = merge({
    Name = var.vpc_name
  }, var.additional_tags)
}

resource "aws_route_table_association" "default_private" {
  count          = length(var.private_subnet_names)
  route_table_id = aws_route_table.default_private[0].id
  subnet_id      = aws_subnet.default_private[count.index].id
}