
output "public_ip" {
  value = element([for instance_suffix in var.instance_suffixes : module.rp_instance[instance_suffix].public_ip], 0)
}

output "private_ip" {
  value = element([for instance_suffix in var.instance_suffixes : module.rp_instance[instance_suffix].private_ip], 0)
}
