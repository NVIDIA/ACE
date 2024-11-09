#!/bin/bash

schema_version="0.0.7"
script_name="${0}"
exec_dir="$(pwd)"
script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
config_file="${script_dir}/config.yml"
tunnel_port="32768"
cluster=""
tmp_dir="$(mktemp -d -p "${script_dir}")"
commands=()

function usage() {
  echo "Usage: ${script_name} (-v|--version)"
  echo "   or: ${script_name} (-h|--help)"
  echo "   or: ${script_name} [options]"
  echo ""
  echo "options:"
  echo "-f, --config-file    path to file containing config overrides, defaults to config.yml"
  echo "-p, --tunnel-port    port between 32768–61000 on which to establish tunnel to CNS cluster, defaults to 32768"
  echo "-c, --cluster        name of the cluster if more than one clusters exist, optional if single cluster exists"
  echo "-h, --help           provide usage information"
}

function execute() {
  validate_args "${@}"
  process_args "${@}"
}

function validate_args() {
  local _args _all_good _valid_args _options _short_options _config_files _tunnel_ports _clusters _sub_commands
  _args=("${@}")
  _all_good=0
  _valid_args=$(getopt -q -o f:p:c:vh --long config-file:tunnel-port:,cluster:,version,help -- "${_args[@]}")
  _all_good=$(( _all_good + $? ))
  if [[ _all_good -gt 0 ]]; then
    echo "Invalid usage: ${_args[*]}"
  else
    eval set -- "${_valid_args}"
    _options=()
    _short_options=()
    _config_files=()
    _tunnel_ports=()
    _clusters=()
    while true; do
      case "${1}" in
        -f | --config-file) _options+=("${1}"); _short_options+=("-f"); shift; _options+=("${1}"); _config_files+=("${exec_dir}/${1}"); shift; ;;
        -p | --tunnel-port) _options+=("${1}"); _short_options+=("-p"); shift; _options+=("${1}"); _tunnel_ports+=("${1}"); shift; ;;
        -c | --cluster) _options+=("${1}"); _short_options+=("-c"); shift; _options+=("${1}"); _clusters+=("${1}"); shift; ;;
        -h | --help) _options+=("${1}"); _short_options+=("-h"); shift; ;;
        -v | --version) _options+=("${1}"); _short_options+=("-v"); shift; ;;
        --) shift; break ;;
      esac
    done
    IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
    IFS=" " read -r -a _config_files <<< "$(de_dupe_elements "${_config_files[@]}")"
    IFS=" " read -r -a _tunnel_ports <<< "$(de_dupe_elements "${_tunnel_ports[@]}")"
    IFS=" " read -r -a _clusters <<< "$(de_dupe_elements "${_clusters[@]}")"
    _sub_commands=()
    while [[ -n "${1}" ]]; do
      _sub_commands+=("${1}")
      shift
    done
    if [[ "${#_sub_commands[@]}" -gt 0 ]]; then
      echo "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 0 ]] && contains_element "-v" "${_short_options[@]}" && [[ "${#_short_options[@]}" -gt 2 ]]; then
      echo "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 0 ]] && contains_element "-v" "${_short_options[@]}" && [[ "${#_short_options[@]}" -eq 2 ]] && ! contains_element "-h" "${_short_options[@]}"; then
      echo "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 0 ]] && ! contains_element "-h" "${_short_options[@]}"; then
      if contains_element "-f" "${_short_options[@]}" && [[ "${#_config_files[@]}" -gt 1 ]]; then
        echo "Multiple config-files provided: ${_config_files[*]}"
        ((_all_good++))
      fi
      if contains_element "-p" "${_short_options[@]}" && [[ "${#_tunnel_ports[@]}" -gt 1 ]]; then
        echo "Multiple tunnel-ports provided: ${_tunnel_ports[*]}"
        ((_all_good++))
      fi
      if contains_element "-c" "${_short_options[@]}" && [[ "${#_clusters[@]}" -gt 1 ]]; then
        echo "Multiple clusters provided: ${_clusters[*]}"
        ((_all_good++))
      fi
    fi
  fi
  if [[ _all_good -gt 0 ]]; then
    echo ""
    usage
    exit 1
  fi
}

function process_args() {
  local _args _valid_args _short_options _config_files _tunnel_ports _clusters
  _args=("${@}")
  _valid_args=$(getopt -q -o f:p:c:vh --long config-file:tunnel-port:,cluster:,version,help -- "${_args[@]}")
  eval set -- "${_valid_args}"
  _short_options=()
  _config_files=()
  _tunnel_ports=()
  _clusters=()
  while true; do
    case "${1}" in
      -f | --config-file) _short_options+=("-f"); shift; _config_files+=("${exec_dir}/${1}"); shift; ;;
      -p | --tunnel-port) _short_options+=("-p"); shift; _tunnel_ports+=("${1}"); shift; ;;
      -c | --cluster) _short_options+=("-c"); shift; _clusters+=("${1}"); shift; ;;
      -h | --help) _short_options+=("-h"); shift; ;;
      -v | --version) _short_options+=("-v"); shift; ;;
      --) shift; break ;;
    esac
  done
  IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
  IFS=" " read -r -a _config_files <<< "$(de_dupe_elements "${_config_files[@]}")"
  IFS=" " read -r -a _tunnel_ports <<< "$(de_dupe_elements "${_tunnel_ports[@]}")"
  IFS=" " read -r -a _clusters <<< "$(de_dupe_elements "${_clusters[@]}")"
  if contains_element "-h" "${_short_options[@]}"; then
    commands+=('usage')
  elif [[ "${#_short_options[@]}" -eq 1 ]] && [[ "${_short_options[0]}" == "-v" ]]; then
    commands+=('print_version')
  else
    if [[ "${#_config_files[@]}" -eq 1 ]]; then
      config_file="${_config_files[0]}"
    fi
    if [[ "${#_tunnel_ports[@]}" -eq 1 ]]; then
      tunnel_port="${_tunnel_ports[0]}"
    fi
    if [[ "${#_clusters[@]}" -eq 1 ]]; then
      cluster="${_clusters[0]}"
    fi
    commands+=('verify_pre_requisites')
    commands+=('activate_venv')
    commands+=('init')
    commands+=('extract_inventory')
    commands+=('check_inventory')
    commands+=('check_cluster_valid')
    commands+=('bootstrap_cns_kubeconfig')
  fi
}

function contains_element() {
  local _element _ref_array _array_element
  _element="${1}"
  _ref_array=("${@:2}")
  for _array_element in "${_ref_array[@]}"
  do
    if [[ "${_element}" == "${_array_element}" ]]; then
      return 0
    fi
  done
  return 1
}

function de_dupe_elements() {
  local _ref_array _de_duped_array _array_element
  _ref_array=("${@}")
  _de_duped_array=()
  for _array_element in "${_ref_array[@]}"
  do
    if [[ "${#_de_duped_array[@]}" -eq 0 ]] || ! contains_element "${_array_element}" "${_de_duped_array[@]}"; then
      _de_duped_array+=("${_array_element}")
    fi
  done
  echo "${_de_duped_array[@]}"
}

function print_version() {
  echo "Version: ${schema_version}"
}

function prompt_acceptance() {
  local _confirm
  read -rp  "Would you like to ${1}? (y/n): " _confirm
  is_yes "${_confirm}"
  return "${?}"
}

function verify_pre_requisites() {
  local _install_or_update_requirement _all_good _requirements _requirement
  _install_or_update_requirement="$(os_supports_install_or_update_of_requirements)"
  _all_good=0
  verify_config
  _all_good=$(( _all_good + $? ))
  verify_tunnel_port
  _all_good=$(( _all_good + $? ))
  verify_privilege_escalation
  _all_good=$(( _all_good + $? ))
  _requirements=()
  _requirements+=('jq')
  _requirements+=('yq')
  _requirements+=('terraform')
  _requirements+=('python3')
  _requirements+=('python3-venv')
  _requirements+=('python3-setuptools')
  _requirements+=('python3-dev')
  _requirements+=('python3-pip')
  for _requirement in "${_requirements[@]}"
  do
    verify_requirement "${_requirement}" "${_install_or_update_requirement}"
    _all_good=$(( _all_good + $? ))
  done
  if [[ _all_good -gt 0 ]]; then
    echo "One or more pre-requisites were not met"
    exit 1
  fi
}

function verify_config() {
  if [[ ! -f "${config_file}" ]]; then
    echo "Config file (${config_file}) not found"
    echo "Please use ${script_dir}/config-template.yml to create the ${config_file}"
    return 1
  fi
}

function verify_tunnel_port() {
  if [[ -z "${tunnel_port}" ]]; then
    echo "Tunnel port is required"
    return 1
  elif [[ "${tunnel_port}" -lt 32768 ]] || [[ "${tunnel_port}" -gt 61000 ]]; then
    echo "Tunnel port should be a number between 32768 and 61000"
    return 1
  else
    return 0
  fi
}

function verify_privilege_escalation() {
  if [[ "${EUID}" -ne 0 ]] && ! sudo -n true &> /dev/null; then
    echo "Current user is neither root, nor has passwordless sudo ability"
    return 1
  else
    return 0
  fi
}

function requirement_present() {
  local _requirement
  _requirement="${1}"
  case "${_requirement}" in
    jq | yq | terraform)
      hash "${_requirement}" 2> /dev/null
      return "${?}"
      ;;
    python3 | python3-venv | python3-setuptools | python3-dev | python3-pip)
      verify_apt_package_present "${_requirement}"
      return "${?}"
      ;;
    *)
      return 1
      ;;
  esac
}

function requirement_version() {
  local _requirement
  _requirement="${1}"
  case "${_requirement}" in
    jq)
      jq --version | cut -d '-' -f 2 2> /dev/null || echo ""
      ;;
    yq)
      yq --version | grep 'mikefarah' | awk '{print $4}' | tr -d 'v' 2> /dev/null || echo ""
      ;;
    terraform)
      terraform --version | head -n 1 | awk '{print $2}' | tr -d 'v' 2> /dev/null || echo ""
      ;;
    python3 | python3-venv | python3-setuptools | python3-dev | python3-pip)
      apt_package_version "${_requirement}"
      ;;
    *)
      echo "0"
      ;;
  esac
}

function requirement_min_version() {
  local _requirement
  _requirement="${1}"
  case "${_requirement}" in
    jq)
      echo '1.6'
      ;;
    yq)
      echo '4.34.1'
      ;;
    terraform)
      echo '1.5.7'
      ;;
    python3 | python3-venv | python3-dev)
      echo '3.9.0'
      ;;
    python3-setuptools)
      echo '59.6.0'
      ;;
    python3-pip)
      echo '22.0.0'
      ;;
    *)
      echo "1"
      ;;
  esac
}

function requirement_max_version() {
  local _requirement
  _requirement="${1}"
  case "${_requirement}" in
    terraform)
      echo '1.5.7'
      ;;
    *)
      echo ""
      ;;
  esac
}

function requirement_install_or_update() {
  local _requirement
  _requirement="${1}"
  case "${_requirement}" in
    yq)
      $(privilege_escalation) wget "https://github.com/mikefarah/yq/releases/download/v$(requirement_min_version "${_requirement}")/yq_linux_amd64" -O /usr/bin/yq
      $(privilege_escalation) chmod +x /usr/bin/yq
      ;;
    terraform)
      curl --silent -L https://raw.githubusercontent.com/versus/terraform-switcher/release/install.sh | $(privilege_escalation) bash
      mkdir -p "${HOME}/bin/terraform"
      tfswitch -qb "${HOME}/bin/terraform" "$(requirement_min_version "${_requirement}")"
      $(privilege_escalation) cp "${HOME}/.terraform.versions/terraform_$(requirement_min_version "${_requirement}")" /usr/local/bin/terraform
      ;;
    jq | python3 | python3-venv | python3-setuptools | python3-dev | python3-pip)
      install_or_update_apt_package "${_requirement}"
      ;;
    *)
      echo "1"
      ;;
  esac
}

function verify_apt_package_present() {
  local _apt_package
  _apt_package="${1}"
  if [[ "$(apt -qq list --installed "${_apt_package}" 2> /dev/null | wc -l)" -eq 1 ]]; then
    return 0;
  else
    return 1;
  fi
}

function apt_package_version() {
  local _apt_package
  _apt_package="${1}"
  apt show "${_apt_package}" 2> /dev/null | grep '^Version' | awk '{print $NF}' | awk -F ':' '{print $NF}' | awk -F '[-+]' '{print $1}'
}

function install_or_update_apt_package() {
  local _apt_package
  _apt_package="${1}"
  $(privilege_escalation) apt update
  $(privilege_escalation) apt-get install "${_apt_package}" -y
}

function verify_min_requirement_version() {
  local _requirement _requirement_version _requirement_min_version
  _requirement="${1}"
  _requirement_version="$(requirement_version "${_requirement}")"
  _requirement_min_version="$(requirement_min_version "${_requirement}")"
  if [[ -n "${_requirement_min_version}" ]] && ! dpkg --compare-versions "${_requirement_version}" ge "${_requirement_min_version}"; then
    return 1
  else
    return "0"
  fi
}

function verify_max_requirement_version() {
  local _requirement _requirement_version _requirement_max_version
  _requirement="${1}"
  _requirement_version="$(requirement_version "${_requirement}")"
  _requirement_max_version="$(requirement_max_version "${_requirement}")"
  if [[ -n "${_requirement_max_version}" ]] && ! dpkg --compare-versions "${_requirement_version}" le "${_requirement_max_version}"; then
    return 1
  else
    return "0"
  fi
}

function install_or_update_requirement() {
  local _requirement
  _requirement="${1}"
  if prompt_acceptance "install/update ${_requirement}"; then
    echo "installing ${_requirement}"
    if ! requirement_install_or_update "${_requirement}" &> /dev/null; then
      echo "failed to install ${_requirement}"
    fi
  fi
}

function get_os() {
  grep -iw ID /etc/os-release | awk -F '=' '{print $2}'
}

function get_os_version() {
  grep -iw VERSION_ID /etc/os-release | awk -F '=' '{print $2}' | tr -d '"'
}

function os_supports_install_or_update_of_requirements() {
  case "$(get_os)-$(get_os_version)" in
    ubuntu-22.04 | ubuntu-24.04)
      echo "yes" ;;
    *)
      echo "no" ;;
  esac
}

function is_yes() {
  if [[ "${1}" == [yY] || "${1}" == [yY][eE][sS] ]]; then
    return 0
  else
    return 1
  fi
}

function verify_requirement() {
  local _requirement
  _requirement="${1}"
  _attempt_install_or_update="${2}"
  if is_yes "${_attempt_install_or_update}" && verify_privilege_escalation &> /dev/null; then
    if ! requirement_present "${_requirement}" || ! verify_min_requirement_version "${_requirement}" || ! verify_max_requirement_version "${_requirement}"; then
      install_or_update_requirement "${_requirement}"
      verify_requirement "${_requirement}" "no"
    fi
  elif ! requirement_present "${_requirement}"; then
    echo "${_requirement} is required"
    return 1
  elif ! verify_min_requirement_version "${_requirement}" && ! verify_max_requirement_version "${_requirement}"; then
    echo "${_requirement} version should be between $(requirement_min_version "${_requirement}") and $(requirement_max_version "${_requirement}")"
    return 1
  elif ! verify_min_requirement_version "${_requirement}"; then
    echo "${_requirement} version should be greater than $(requirement_min_version "${_requirement}")"
    return 1
  elif ! verify_max_requirement_version "${_requirement}"; then
    echo "${_requirement} version should be lesser than $(requirement_max_version "${_requirement}")"
    return 1
  else
    return 0
  fi
}

function privilege_escalation() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo -n "sudo"
  else
    echo -n ""
  fi
}

function exit_if_not_ok() {
  if [[ "${1}" != "0" ]]; then
    exit "${1}"
  fi
}

function deactivate_venv() {
  deactivate 2> /dev/null || true
}

function activate_venv() {
  deactivate_venv
  {
    python3 -m venv --copies --clear "${script_dir}/ansible-venv"
    source "${script_dir}/ansible-venv/bin/activate"
  } > /dev/null
  trap deactivate_venv EXIT
  {
    pip install --upgrade pip
    pip install ansible==7.0.0
  } > /dev/null
  if ! hash deactivate 2> /dev/null; then
    echo "Failed to activate virtualenv"
    exit 1
  fi
}

function abort_option() {
  echo "CTRL-C to abort"
  sleep 10
}

function switch_to_script_dir() {
  cd "${script_dir}" || exit 1
}

function init() {
  local _tmp_init_dir _config_yml _infra_yml _tf_backend_json _tf_variables_json _uncommented_config_file _name
  echo "preparing artifacts"
  switch_to_script_dir

  _tmp_init_dir="${tmp_dir}/init"
  mkdir -p "${_tmp_init_dir}"
  _config_yml="${_tmp_init_dir}/config.yml"
  _infra_yml="${_tmp_init_dir}/infra.yml"
  _tf_backend_json="${_tmp_init_dir}/tf-backend.json"
  _tf_variables_json="${_tmp_init_dir}/tf-variables.json"
  _uncommented_config_file="${_tmp_init_dir}/uncommented_config.yml"

  # prepare _config_yml
  sed '/^[[:space:]]*#/d' "${config_file}" > "${_uncommented_config_file}"
  process_user_config "${_uncommented_config_file}" "${_config_yml}"

  # get _name
  _name="$(yq eval '.name' "${_config_yml}")"

  # prepare _infra_yml
  yq eval '.spec.infra' "${_config_yml}" > "${_infra_yml}"

  # prepare _tf_backend_json
  case "$(yq eval '.csp' "${_infra_yml}")" in
    aws | azure)
      jq -n \
        --arg name "${_name}" \
        --argjson config "$(yq eval '.backend' "${_infra_yml}" -o=json)" \
        '$config * { key: ($name + "/terraform.tfstate") }' > "${_tf_backend_json}"
      ;;
    gcp)
      jq -n \
        --arg name "${_name}" \
        --argjson config "$(yq eval '.backend' "${_infra_yml}" -o=json)" \
        '$config * { prefix: ($name + "/terraform.tfstate") }' > "${_tf_backend_json}"
      ;;
    oci)
      jq -n \
        --arg name "${_name}" \
        --arg par "$(yq eval '.backend.pre_authenticated_request' "${_infra_yml}")" \
        '{ address: ($par + $name + "/terraform.tfstate"), update_method: "PUT" }' > "${_tf_backend_json}"
      ;;
    bm)
      _bm_state_dir="${HOME}/.nvoc/tf-state"
      mkdir -p "${_bm_state_dir}/${_name}"
      jq -n \
        --arg bm_state_dir "${_bm_state_dir}" \
        --arg name "${_name}" \
        '{ path: ($bm_state_dir + "/" + $name + "/terraform.tfstate") }' > "${_tf_backend_json}"
      ;;
    *)
      jq -n '{}' > "${_tf_backend_json}"
      ;;
  esac

  # prepare _tf_variables_json
  jq -n \
   --arg name "${_name}" \
   --argjson controller_ip "$(jq -n --arg ip "$(curl -s ifconfig.me)" '{ controller_ip: $ip }')" \
   --argjson provider "$(yq eval '.provider' "${_infra_yml}" -o=json | jq '{provider_config: .}')" \
   --argjson configs "$(yq eval '.configs' "${_infra_yml}" -o=json)" \
    '{ name: $name } * $controller_ip * $provider * $configs' >  "${_tf_variables_json}"

  cp -r iac-ref iac
  cp "${_tf_backend_json}" iac/tf-backend.json
  cp "${_tf_variables_json}" iac/tf-variables.json
}

function extract_inventory() {
  local _exit_code
  echo "extracting inventory"
  switch_to_script_dir
  terraform -chdir="iac" init -reconfigure -backend-config=tf-backend.json > /dev/null
  terraform -chdir="iac" plan -compact-warnings -out=tf-plan -var-file=tf-variables.json -detailed-exitcode 1> /dev/null 2> /dev/null
  _exit_code=$?
  if [[ "${_exit_code}" != "0" ]]; then
    echo "cannot extract inventory when there are IaC changes"
    rm inventory.yml &> /dev/null || true
    rm cns-host-groups.json &> /dev/null || true
    rm ssh-commands.json &> /dev/null || true
    return 1
  else
    terraform -chdir="iac" output -json | jq -r '.hosts.value' > inventory.yml
    terraform -chdir="iac" output -json | jq -r '.cns_clusters.value // {}' > cns-clusters.json
    return 0
  fi
}

function check_inventory() {
  local _retry_counter
  echo "checking inventory"
  switch_to_script_dir
  _retry_counter=0
  while ! ansible-playbook -i inventory.yml playbooks/check-inventory.yml > /dev/null 2> /dev/null; do
    if [[ "${_retry_counter}" -ge 15 ]]; then
      echo "exhausted attempts waiting for inventory to be ready"
      return 1
    else
      ((_retry_counter++))
      echo "waiting for inventory to be ready"
      sleep 20
    fi
  done
  return 0
}

function check_cluster_valid() {
  echo "checking cluster valid"
  switch_to_script_dir
  if [[ -n "${cluster}" ]] && [[ "$(jq --arg cluster "${cluster}" 'has($cluster)' < cns-clusters.json)" == "true" ]]; then
    return 0
  elif [[ -z "${cluster}" ]] && [[ "$(jq '. | to_entries | length' < cns-clusters.json)" -eq 1 ]]; then
    cluster="$(jq -r 'keys[0]' < cns-clusters.json)"
    return 0
  else
    echo "Invalid or ambiguous cluster"
    return 1
  fi
}

function bootstrap_cns_kubeconfig() {
  local _cluster_master _cluster_name
  switch_to_script_dir
  _cluster_master="$(jq -r --arg cluster "${cluster}" '.[$cluster].master_name' < cns-clusters.json)"
  jq -r --arg cluster "${cluster}" '.[$cluster].ssh_command' < cns-clusters.json > ssh-command.sh
  _cluster_name="$(jq -r '.name' < iac/tf-variables.json)-${cluster}"
  ANSIBLE_JINJA2_NATIVE=true ansible-playbook \
    -l "localhost,${_cluster_master}" \
    -i inventory.yml \
    -e cluster_name="${_cluster_name}" \
    -e ssh_command="${script_dir}/ssh-command.sh" \
    -e tunnel_port="${tunnel_port}" \
    playbooks/bootstrap-cns-kubeconfig.yml
}

function process_user_config() {
  local _input_file _output_file
  _input_file="${1}"
  _output_file="${2}"
  if ! ANSIBLE_JINJA2_NATIVE=true ansible-playbook \
      -c local \
      -i localhost, \
      -e input_file="${_input_file}" \
      -e output_file="${_output_file}" \
      playbooks/process-user-config.yml &> /dev/null; then
    echo "could not process config file: ${_input_file}"
    exit 1
  fi
}

function cleanup() {
  switch_to_script_dir
  rm -rf "${tmp_dir}" 2> /dev/null
}

function abort() {
  echo "Aborting as SIGTERM/SIGINT received"
  trap - SIGINT SIGTERM # clear the trap
  kill -- -$$ # Sends SIGTERM to child/sub processes
}

trap cleanup EXIT
trap abort SIGINT SIGTERM

execute "${@}"
for command in "${commands[@]}"
do
  "${command}"
  exit_if_not_ok "${?}"
done
