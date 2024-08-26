
module "rp_instance" {
  source                = "../../aws/ec2"
  for_each              = toset(var.instance_suffixes)
  instance_type         = local.instance_details.instance_type
  instance_name         = format("%s-%s", local.name, each.key)
  ami_lookup            = local.app_ami_lookup
  ec2_key               = var.base_config.keypair.name
  root_volume_type      = local.instance_details.root_volume_type
  root_volume_size      = local.instance_details.root_volume_size
  instance_profile_name = aws_iam_instance_profile.instance.name
  vpc_id                = var.base_config.networking.vpc_id
  subnet_id             = element(var.base_config.networking.public_subnet_ids, 0)
  additional_sg_ids     = var.base_config.rp_sg_ids
  include_public_ip     = false
  user_data = templatefile("${path.module}/user-data/user-data.sh.tpl", {
    name           = local.name
    config_bucket  = var.base_config.config_bucket
    config_scripts = local.config_scripts
  })
  ebs_block_devices = local.instance_details.data_disks
}