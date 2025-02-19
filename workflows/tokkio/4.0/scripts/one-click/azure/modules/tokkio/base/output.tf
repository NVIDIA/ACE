
output "resource_group" {
  value = module.resource_group
}
output "networking" {
  value = {
    region               = module.networking.region
    bastion_vm_subnet_id = module.networking.subnet_ids[local.bastion_vm_details.subnet_identifier]
    api_app_gw_subnet_id = module.networking.subnet_ids[local.app_gw_subnet_identifier]
    coturn_vm_subnet_id  = module.networking.subnet_ids[local.coturn_subnet_identifier]
    rp_vm_subnet_id      = module.networking.subnet_ids[local.rp_subnet_identifier]
    api_vm_subnet_id     = module.networking.subnet_ids[local.app_api_subnet_identifier]
  }
}
output "keypair" {
  value = module.keypair
}
output "bastion_vm" {
  value = {
    public_ip  = module.bastion_vm.public_ip
    private_ip = module.bastion_vm.private_ip
  }
}
output "config_storage_account" {
  value = {
    id   = module.config_storage_account.id
    name = module.config_storage_account.name
    reader_identity = {
      id        = azurerm_user_assigned_identity.config_reader.id
      client_id = azurerm_user_assigned_identity.config_reader.client_id
    }
    reader_access = {
      id = azurerm_role_assignment.config_reader_access.id
    }
  }
}
output "domain_name" {
  value = data.azurerm_dns_zone.dns_zone.name
}
output "wildcard_cert" {
  value     = data.azurerm_key_vault_secret.wildcard_certificate_secret.value
  sensitive = true
}