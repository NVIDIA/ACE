
locals {
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  star_base_domain   = format("*.%s", var.base_domain)

  bastion_ami_name_defaults = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  bastion_ami_name          = var.bastion_ami_name == null ? local.bastion_ami_name_defaults : var.bastion_ami_name
  bastion_ami_lookup = {
    owners = ["099720109477"] # Canonical
    filters = [
      {
        name   = "name"
        values = [local.bastion_ami_name]
      },
      {
        name   = "virtualization-type"
        values = ["hvm"]
      }
    ]
  }

  bastion_instance_details = {
    instance_type    = "t3.micro"
    root_volume_type = "gp3"
    root_volume_size = 50
  }

}

