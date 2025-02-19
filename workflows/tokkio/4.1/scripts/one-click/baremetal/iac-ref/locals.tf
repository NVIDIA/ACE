locals {
  cluster_names          = sort(keys(var.clusters))
  bastion_inventory_name = "bastion"
  master_inventory_name  = "master"
  ansible_ssh_extra_args = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  turn_server_provider = var.turn_server_provider
  use_reverse_proxy = local.turn_server_provider == "rp" ? true : false
  use_twilio_stun_turn = local.turn_server_provider == "twilio" ? true : false
}