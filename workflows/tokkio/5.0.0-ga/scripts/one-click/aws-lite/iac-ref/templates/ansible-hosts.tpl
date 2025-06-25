%{~ if length(cns_clusters) > 0 ~}
cns_clusters:
  children:
    master:
      hosts:
        %{~ for cns_cluster in cns_clusters ~}
        ${cns_cluster.name}-${cns_cluster.master.name}:
          ansible_user: ${cns_cluster.master.user}
          ansible_host: ${cns_cluster.master.host}
          ansible_ssh_private_key_file: ${cns_cluster.master.private_key_file}
          ansible_ssh_extra_args: '${ansible_ssh_extra_args}'
        %{~ endfor ~}
%{~ endif ~}