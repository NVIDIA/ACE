
locals {
  lookup_ami  = length(var.ami_lookup.owners) > 0 && length(var.ami_lookup.filters) > 0
  instance_id = one(concat(aws_instance.this.*.id, aws_instance.that.*.id))
  public_ip   = one(concat(aws_instance.this.*.public_ip, aws_instance.that.*.public_ip))
}

data "aws_ami" "lookup" {
  count       = local.lookup_ami ? 1 : 0
  most_recent = true
  owners      = var.ami_lookup.owners
  dynamic "filter" {
    for_each = var.ami_lookup.filters
    content {
      name   = filter.value["name"]
      values = filter.value["values"]
    }
  }
}

resource "aws_security_group" "this" {
  count  = length(var.ingress_rules) > 0 ? 1 : 0
  name   = format("%s-sg", var.instance_name)
  vpc_id = var.vpc_id
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description      = ingress.value["description"]
      from_port        = ingress.value["from_port"]
      to_port          = ingress.value["to_port"]
      protocol         = ingress.value["protocol"]
      cidr_blocks      = ingress.value["cidr_blocks"]
      ipv6_cidr_blocks = ingress.value["ipv6_cidr_blocks"]
      security_groups  = ingress.value["security_groups"]
      self             = ingress.value["self"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "this" {
  count = var.include_public_ip ? 1 : 0
  vpc   = true
  tags = merge({
    Name = var.instance_name
  }, var.additional_tags)
}

resource "aws_network_interface" "this" {
  subnet_id       = var.subnet_id
  security_groups = concat(aws_security_group.this.*.id, var.additional_sg_ids)
}

resource "aws_instance" "this" {
  count                       = local.lookup_ami ? 1 : 0
  ami                         = data.aws_ami.lookup[count.index].id
  instance_type               = var.instance_type
  key_name                    = var.ec2_key
  iam_instance_profile        = var.instance_profile_name
  user_data                   = var.user_data
  user_data_replace_on_change = true
  network_interface {
    network_interface_id = aws_network_interface.this.id
    device_index         = 0
  }
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }
  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.volume_size
      volume_type = ebs_block_device.value.volume_type
    }
  }
  tags = merge({
    Name = var.instance_name
  }, var.additional_tags)
  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "that" {
  count                       = local.lookup_ami ? 0 : 1
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.ec2_key
  iam_instance_profile        = var.instance_profile_name
  user_data                   = var.user_data
  user_data_replace_on_change = true
  network_interface {
    network_interface_id = aws_network_interface.this.id
    device_index         = 0
  }
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
  }
  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.volume_size
      volume_type = ebs_block_device.value.volume_type
    }
  }
  tags = merge({
    Name = var.instance_name
  }, var.additional_tags)
}

resource "aws_eip_association" "this" {
  count         = var.include_public_ip ? 1 : 0
  instance_id   = local.instance_id
  allocation_id = aws_eip.this[count.index].id
}