
output "public_ip" {
  value = module.rp_vm.public_ip

}

output "private_ip" {
  value = module.rp_vm.private_ip
}
