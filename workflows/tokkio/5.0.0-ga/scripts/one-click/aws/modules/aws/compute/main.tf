resource "aws_eip" "default" {
  count  = var.include_elastic_ip ? 1 : 0
  #domain = "vpc"
  tags = merge({
    Name = var.instance_name
  }, var.additional_tags)
}

resource "aws_network_interface" "default" {
  subnet_id       = var.subnet_id
  security_groups = var.security_groups
}

resource "aws_key_pair" "default" {
  key_name_prefix = var.instance_name
  public_key      = var.public_key
  tags = merge({
    Name = var.instance_name
  }, var.additional_tags)
}

resource "aws_instance" "default" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.default.key_name
  iam_instance_profile        = var.instance_profile_name
  user_data                   = var.user_data
  user_data_replace_on_change = true
  network_interface {
    network_interface_id = aws_network_interface.default.id
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

resource "aws_eip_association" "default" {
  count         = var.include_elastic_ip ? 1 : 0
  instance_id   = aws_instance.default.id
  allocation_id = aws_eip.default[count.index].id
}