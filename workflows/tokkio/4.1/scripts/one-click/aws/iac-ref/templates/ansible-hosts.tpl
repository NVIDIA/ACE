%{~ if length(jump_hosts) > 0 ~}
jump_hosts:
  hosts:
    %{~ for jump_host in jump_hosts ~}
    ${jump_host.name}:
      ansible_user: ${jump_host.user}
      ansible_host: ${jump_host.host}
      ansible_ssh_private_key_file: ${jump_host.private_key_file}
      ansible_ssh_extra_args: '${ansible_ssh_extra_args}'
    %{~ endfor ~}
%{~ endif ~}
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
          %{~ if cns_cluster.bastion != null ~}
          ansible_ssh_extra_args: '${ansible_ssh_extra_args} -o ProxyCommand="ssh -i ${cns_cluster.bastion.private_key_file} -W %h:%p ${cns_cluster.bastion.user}@${cns_cluster.bastion.host} ${ansible_ssh_extra_args}"'
          %{~ else ~}
          ansible_ssh_extra_args: '${ansible_ssh_extra_args}'
          %{~ endif ~}
        %{~ endfor ~}
    %{~ if length(flatten(cns_clusters[*].nodes)) > 0 ~}
    nodes:
      hosts:
        %{~ for cns_cluster in cns_clusters ~}
        %{~ for node in cns_cluster.nodes ~}
        ${cns_cluster.name}-${node.name}:
          ansible_user: ${node.user}
          ansible_host: ${node.host}
          ansible_ssh_private_key_file: ${node.private_key_file}
          %{~ if cns_cluster.bastion != null ~}
          ansible_ssh_extra_args: '${ansible_ssh_extra_args} -o ProxyCommand="ssh -i ${cns_cluster.bastion.private_key_file} -W %h:%p ${cns_cluster.bastion.user}@${cns_cluster.bastion.host} ${ansible_ssh_extra_args}"'
          %{~ else ~}
          ansible_ssh_extra_args: '${ansible_ssh_extra_args}'
          %{~ endif ~}
        %{~ endfor ~}
        %{~ endfor ~}
    %{~ endif ~}
%{~ endif ~}