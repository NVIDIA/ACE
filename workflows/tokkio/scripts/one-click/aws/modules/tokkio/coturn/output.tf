
output "public_ip" {
  value = module.coturn_instance.public_ip
}
output "private_ip" {
  value = module.coturn_instance.private_ip
}
output "coturn_instance" {
  value = module.coturn_instance
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