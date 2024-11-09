output "info" {
  value = {
    access_urls = {
      api_endpoint           = "https://${local.api_domain}"
      ui_endpoint            = "https://${local.ui_domain}"
      elasticsearch_endpoint = "https://${local.elastic_domain}"
      kibana_endpoint = "https://${local.kibana_domain}"
      grafana_endpoint = "https://${local.grafana_domain}"
    }
    # access_urls = {
    #   for cluster in sort(keys(var.clusters)) :
    #   cluster => {
    #     for port_name in sort(keys(var.clusters[cluster].ports)) :
    #     port_name => format(
    #       "%s://%s:%s/%s",
    #       var.clusters[cluster].ports[port_name].protocol,
    #       var.clusters[cluster].private_instance ? module.alb[cluster].dns_name : module.master[cluster].public_ip,
    #       var.clusters[cluster].ports[port_name].port,
    #       trimprefix(var.clusters[cluster].ports[port_name].path, "/")
    #     )
    #   }
    # }
    ssh_command : {
      for cluster in sort(keys(var.clusters)) :
      cluster => merge(
        {
          bastion = var.clusters[cluster].private_instance ? format(
            "ssh -i %s %s %s@%s",
            var.ssh_private_key_path,
            local.ansible_ssh_extra_args,
            local.ssh_user,
            one(module.bastion[*].public_ip)
          ) : null
          master = format(
            "ssh -i %s %s%s %s@%s",
            var.ssh_private_key_path,
            local.ansible_ssh_extra_args,
            var.clusters[cluster].private_instance ? format(" -o ProxyCommand=\"%s\"",
              format("ssh -i %s %s -W %s %s@%s",
                var.ssh_private_key_path,
                local.ansible_ssh_extra_args,
                "%h:%p",
                local.ssh_user,
                one(module.bastion[*].public_ip)
              )
            ) : "",
            local.ssh_user,
            var.clusters[cluster].private_instance ? module.master[cluster].private_ip : module.master[cluster].public_ip
          )
        },
        {
          for node in keys(var.clusters[cluster].nodes) :
          node =>
          format(
            "ssh -i %s %s%s %s@%s",
            var.ssh_private_key_path,
            local.ansible_ssh_extra_args,
            var.clusters[cluster].private_instance ? format(" -o ProxyCommand=\"%s\"",
              format("ssh -i %s %s -W %s %s@%s",
                var.ssh_private_key_path,
                local.ansible_ssh_extra_args,
                "%h:%p",
                local.ssh_user,
                one(module.bastion[*].public_ip)
              )
            ) : "",
            local.ssh_user,
            module.node[format("%s-%s", cluster, node)].private_ip
          )
        }
      )
    }
  }
}

output "hosts" {
  value = templatefile("${path.module}/templates/ansible-hosts.tpl", {
    jump_hosts = [for host in module.bastion[*].public_ip : {
      name             = local.bastion_inventory_name
      user             = local.ssh_user
      host             = host
      private_key_file = var.ssh_private_key_path
    }]
    cns_clusters = [for cluster in sort(keys(var.clusters)) :
      {
        name = cluster
        bastion = var.clusters[cluster].private_instance ? {
          user             = local.ssh_user
          host             = one(module.bastion[*].public_ip)
          private_key_file = var.ssh_private_key_path
        } : null
        master = {
          name             = local.master_inventory_name
          user             = local.ssh_user
          host             = var.clusters[cluster].private_instance ? module.master[cluster].private_ip : module.master[cluster].public_ip
          private_key_file = var.ssh_private_key_path
        }
        nodes = [for node in keys(var.clusters[cluster].nodes) : {
          name             = node
          user             = local.ssh_user
          host             = var.clusters[cluster].private_instance ? module.node[format("%s-%s", cluster, node)].private_ip : module.node[format("%s-%s", cluster, node)].public_ip
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
      ssh_command = var.clusters[cluster].private_instance ? format("ssh -i %s %s -o ProxyCommand=\"%s\" %s@%s", var.ssh_private_key_path, local.ansible_ssh_extra_args, format("ssh -i %s %s -W %s %s@%s", var.ssh_private_key_path, local.ansible_ssh_extra_args, "%h:%p", local.ssh_user, one(module.bastion[*].public_ip)), local.ssh_user, module.master[cluster].private_ip) : format("ssh -i %s %s %s@%s", var.ssh_private_key_path, local.ansible_ssh_extra_args, local.ssh_user, module.master[cluster].public_ip)
    }
  }
}

output "playbook_configs" {
  value = {
    jump_hosts = {
      for bastion in module.bastion[*] :
      "bastion" => {
        target                     = local.bastion_inventory_name
        additional_ssh_public_keys = var.additional_ssh_public_keys
      }
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
        ip_addresses = {
          public_ip = module.master[cluster].public_ip
          private_ip = module.master[cluster].private_ip
        }
        endpoint = {
          api_endpoint =  var.clusters[cluster].private_instance ? local.api_domain : null
        }
        ui_storage = {
          ui_bucket_id = var.clusters[cluster].private_instance ? aws_s3_bucket.ui_bucket.id : null
        }
        platform = {
          elasticsearch_endpoint = local.elastic_domain
          kibana_endpoint = local.kibana_domain
          grafana_endpoint = local.grafana_domain        
        }
        use_reverse_proxy = local.use_reverse_proxy
        use_twilio_stun_turn = local.use_twilio_stun_turn
      }
    }
  }
}