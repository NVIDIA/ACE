
output "public_ip" {
  value = module.coturn_vm.public_ip
}
output "private_ip" {
  value = module.coturn_vm.private_ip
}
output "port" {
  value = 3478
}
output "realm" {
  value = var.turnserver_realm
}
output "username" {
  value     = var.turnserver_username
  sensitive = true
}
output "password" {
  value     = var.turnserver_password
  sensitive = true
}