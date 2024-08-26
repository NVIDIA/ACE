
module "bastion_instance" {
  source                = "../../aws/ec2"
  instance_type         = local.bastion_instance_details.instance_type
  instance_name         = format("%s-bastion", var.name)
  ami_lookup            = local.bastion_ami_lookup
  ec2_key               = module.key_pair.name
  root_volume_type      = local.bastion_instance_details.root_volume_type
  root_volume_size      = local.bastion_instance_details.root_volume_size
  instance_profile_name = null
  vpc_id                = local.vpc_id
  subnet_id             = element(local.public_subnet_ids, 0)
  additional_sg_ids     = [module.bastion_security_group.security_group_id]
  include_public_ip     = true
}