
resource "aws_security_group" "this" {
  count  = length(var.ingress_rules) > 0 ? 1 : 0
  name   = format("%s-sg", var.name)
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

resource "aws_lb" "this" {
  name            = var.name
  security_groups = concat(aws_security_group.this.*.id, var.additional_sg_ids)
  subnets         = var.subnet_ids
  idle_timeout    = var.idle_timeout
  tags = merge({
    Name = var.name
  }, var.additional_tags)
}