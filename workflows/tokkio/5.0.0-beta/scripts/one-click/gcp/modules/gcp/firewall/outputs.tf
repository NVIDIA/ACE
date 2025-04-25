output "firewall_policies" {
  value = {
    for k, v in google_compute_network_firewall_policy.default : k => v
  }
  description = "The outputs of the created firewall policies."
}

output "firewall_policy_rules" {
  value = {
    for k, v in google_compute_network_firewall_policy_rule.default : k => v
  }
  description = "The outputs of the created firewall policy rules."
}