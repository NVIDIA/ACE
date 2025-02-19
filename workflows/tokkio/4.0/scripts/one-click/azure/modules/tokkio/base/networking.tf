
module "networking" {
  source                        = "../../azure/networking"
  name                          = var.name
  resource_group_name           = module.resource_group.name
  region                        = var.region
  virtual_network_address_space = var.virtual_network_address_space
  subnet_details                = local.subnet_details
  network_security_groups       = local.network_security_groups
  network_security_rules        = local.network_security_rules
}