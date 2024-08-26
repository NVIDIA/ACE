
output "public_ip" {
  value = module.instance.public_ip
}
output "private_ip" {
  value = module.instance.private_ip
}
output "port" {
  value = 3478
}
output "realm" {
  value = var.coturn_settings.realm
}
output "username" {
  value     = var.coturn_settings.username
  sensitive = true
}
output "password" {
  value     = var.coturn_settings.password
  sensitive = true
}