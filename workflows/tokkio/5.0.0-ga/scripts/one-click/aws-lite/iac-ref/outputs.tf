output "info" {
  value = {
    # access_urls = {
    #   api_endpoint           = "https://${local.api_domain}"
    #   ui_endpoint            = "https://${local.ui_domain}"
    #   grafana_endpoint = "https://${local.grafana_domain}"
    #   ace_configurator_endpoint = "https://${local.ace_configurator_domain}"
    # }
    access_urls = {
      for cluster in sort(keys(var.clusters)) :
      cluster => {
        for port_name in sort(keys(var.clusters[cluster].ports)) :
        port_name => format(
          "%s://%s:%s/%s",
          var.clusters[cluster].ports[port_name].protocol,
          module.master[cluster].public_ip,
          var.clusters[cluster].ports[port_name].port,
          trimprefix(var.clusters[cluster].ports[port_name].path, "/")
        )
      }
    }
    ssh_command : {
      for cluster in sort(keys(var.clusters)) :
      cluster => merge(
        {
          master = format(
            "ssh -i %s %s %s@%s",
            var.ssh_private_key_path,
            local.ansible_ssh_extra_args,
            local.ssh_user,
            module.master[cluster].public_ip
          )
        }
      )
    }
  }
}

output "hosts" {
  value = templatefile("${path.module}/templates/ansible-hosts.tpl", {
    cns_clusters = [for cluster in sort(keys(var.clusters)) :
      {
        name = cluster
        master = {
          name             = local.master_inventory_name
          user             = local.ssh_user
          host             = module.master[cluster].public_ip
          private_key_file = var.ssh_private_key_path
        }
      }
    ]
    ansible_ssh_extra_args = local.ansible_ssh_extra_args
  })
}

output "cns_clusters" {
  value = {
    for cluster in sort(keys(var.clusters)) :
    cluster => {
      master_name = format("%s-%s", cluster, local.master_inventory_name)
      ssh_command = format("ssh -i %s %s %s@%s", var.ssh_private_key_path, local.ansible_ssh_extra_args, local.ssh_user, module.master[cluster].public_ip)
    }
  }
}

output "playbook_configs" {
  value = {
    clusters = {
      for cluster in sort(keys(var.clusters)) :
      cluster => {
        targets = {
          all = join(":", [
            for node_suffix in concat(
              [local.master_inventory_name],
              [for node in keys(var.clusters[cluster].nodes) : node]
            ) : format("%s-%s", cluster, node_suffix)
          ])
          master = format("%s-%s", cluster, local.master_inventory_name)
        }
        ports = {
          for port_name in sort(keys(var.clusters[cluster].ports)) :
          port_name => var.clusters[cluster].ports[port_name].port
        }
        labels = {
          for l in concat(
            [
              {
                inventory = format("%s-%s", cluster, local.master_inventory_name)
                labels    = var.clusters[cluster].master["labels"]
              }
            ],
            [
              for node in keys(var.clusters[cluster].nodes) :
              {
                inventory = format("%s-%s", cluster, node)
                labels    = var.clusters[cluster].nodes[node]["labels"]
              }
            ]
          ) :
          l.inventory => l.labels
        }
        taints = {
          for t in concat(
            [
              {
                inventory = format("%s-%s", cluster, local.master_inventory_name)
                taints    = var.clusters[cluster].master["taints"]
              }
            ],
            [
              for node in keys(var.clusters[cluster].nodes) :
              {
                inventory = format("%s-%s", cluster, node)
                taints    = var.clusters[cluster].nodes[node]["taints"]
              }
            ]
          ) :
          t.inventory => t.taints
        }
        features                   = sort([for feature, enabled in var.clusters[cluster].features : feature if enabled])
        additional_ssh_public_keys = var.additional_ssh_public_keys
        ip_addresses = {
          public_ip  = module.master[cluster].public_ip
          private_ip = module.master[cluster].private_ip
        }
        use_twilio_stun_turn = local.use_twilio_stun_turn
      }
    }
  }
}