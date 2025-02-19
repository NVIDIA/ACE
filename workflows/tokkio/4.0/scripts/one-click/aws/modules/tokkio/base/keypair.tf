
module "key_pair" {
  source     = "../../aws/keypair"
  public_key = var.ssh_public_key
  key_name   = format("%s-key", var.name)
}