
module "keypair" {
  source              = "../../azure/keypair"
  name                = var.name
  resource_group_name = module.resource_group.name
  region              = var.region
  public_key          = var.ssh_public_key
}