
resource "google_service_account" "bastion_instance_service_account" {
  account_id = local.bastion_config.name
}

module "bastion_instance" {
  source                 = "../../gcp/instance"
  name                   = local.bastion_config.name
  region                 = local.bastion_config.region
  zone                   = local.bastion_config.zone
  network                = local.bastion_config.network
  subnetwork             = local.bastion_config.subnetwork
  static_public_ip       = local.bastion_config.static_public_ip
  network_interface      = local.bastion_config.network_interface
  tags                   = local.bastion_config.tags
  machine_type           = local.bastion_config.machine_type
  service_account_email  = google_service_account.bastion_instance_service_account.email
  service_account_scopes = local.bastion_config.service_account_scopes
  boot_disk              = local.bastion_config.boot_disk
  ssh_public_key         = local.bastion_config.ssh_public_key
  ssh_user               = local.bastion_config.ssh_user
}