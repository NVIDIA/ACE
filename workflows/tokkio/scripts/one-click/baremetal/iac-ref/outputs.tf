output "info" {
  value = {
    access_urls = {
      for cluster in sort(keys(var.clusters)) :
      cluster => {
        for port_name in sort(keys(var.clusters[cluster].ports)) :
        port_name => format(
          "%s://%s:%s/%s",
          var.clusters[cluster].ports[port_name].protocol,
          var.clusters[cluster].master.host,
          var.clusters[cluster].ports[port_name].port,
          trimprefix(var.clusters[cluster].ports[port_name].path, "/")
        )
      }
    }
    ssh_command : {
      for cluster in sort(keys(var.clusters)) :
      cluster => merge(
        {
          bastion = var.clusters[cluster].bastion != null ? format(
            "ssh -i %s %s %s@%s",
            var.ssh_private_key_path,
            local.ansible_ssh_extra_args,
            var.clusters[cluster].bastion.user,
            var.clusters[cluster].bastion.host
          ) : null
          master = format(
            "ssh -i %s %s%s %s@%s",
            var.ssh_private_key_path,
            local.ansible_ssh_extra_args,
            var.clusters[cluster].bastion != null ? format(" -o ProxyCommand=\"%s\"",
              format("ssh -i %s %s -W %s %s@%s",
                var.ssh_private_key_path,
                local.ansible_ssh_extra_args,
                "%h:%p",
                var.clusters[cluster].bastion.user,
                var.clusters[cluster].bastion.host
              )
            ) : "",
            var.clusters[cluster].master.user,
            var.clusters[cluster].master.host
          )
        },
        {
          for node in keys(var.clusters[cluster].nodes) :
          node =>
          format(
            "ssh -i %s %s%s %s@%s",
            var.ssh_private_key_path,
            local.ansible_ssh_extra_args,
            var.clusters[cluster].bastion != null ? format(" -o ProxyCommand=\"%s\"",
              format("ssh -i %s %s -W %s %s@%s",
                var.ssh_private_key_path,
                local.ansible_ssh_extra_args,
                "%h:%p",
                var.clusters[cluster].bastion.user,
                var.clusters[cluster].bastion.host
              )
            ) : "",
            var.clusters[cluster].nodes[node].user,
            var.clusters[cluster].nodes[node].host
          )
        }
      )
    }
  }
}

output "hosts" {
  value = templatefile("${path.module}/templates/ansible-hosts.tpl", {
    jump_hosts = [for cluster in sort(keys(var.clusters)) : {
      name             = format("%s-%s", cluster, local.bastion_inventory_name)
      user             = var.clusters[cluster].bastion.user
      host             = var.clusters[cluster].bastion.host
      private_key_file = var.ssh_private_key_path
    } if var.clusters[cluster].bastion != null]
    cns_clusters = [for cluster in sort(keys(var.clusters)) :
      {
        name = cluster
        bastion = var.clusters[cluster].bastion != null ? {
          user             = var.clusters[cluster].bastion.user
          host             = var.clusters[cluster].bastion.host
          private_key_file = var.ssh_private_key_path
        } : null
        master = {
          name             = local.master_inventory_name
          user             = var.clusters[cluster].master.user
          host             = var.clusters[cluster].master.host
          private_key_file = var.ssh_private_key_path
        }
        nodes = [for node in keys(var.clusters[cluster].nodes) : {
          name             = node
          user             = var.clusters[cluster].nodes[node].user
          host             = var.clusters[cluster].nodes[node].host
          private_key_file = var.ssh_private_key_path
        }]
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
      ssh_command = var.clusters[cluster].bastion != null ? format("ssh -i %s %s -o ProxyCommand=\"%s\" %s@%s", var.ssh_private_key_path, local.ansible_ssh_extra_args, format("ssh -i %s %s -W %s %s@%s", var.ssh_private_key_path, local.ansible_ssh_extra_args, "%h:%p", var.clusters[cluster].bastion.user, var.clusters[cluster].bastion.host), var.clusters[cluster].master.user, var.clusters[cluster].master.host) : format("ssh -i %s %s %s@%s", var.ssh_private_key_path, local.ansible_ssh_extra_args, var.clusters[cluster].master.user, var.clusters[cluster].master.host)
    }
  }
}

output "playbook_configs" {
  value = {
    jump_hosts = {
      for cluster in sort(keys(var.clusters)) :
      format("%s-bastion", cluster) => {
        target                     = format("%s-%s", cluster, local.bastion_inventory_name)
        additional_ssh_public_keys = var.additional_ssh_public_keys
      } if var.clusters[cluster].bastion != null
    }
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
        ip_address = var.clusters[cluster].master.host
        use_reverse_proxy = local.use_reverse_proxy
        use_twilio_stun_turn = local.use_twilio_stun_turn        
      }
    }
  }
}