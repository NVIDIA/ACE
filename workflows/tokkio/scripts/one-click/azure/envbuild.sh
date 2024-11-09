#!/bin/bash

schema_version="0.0.7"
script_name="${0}"
exec_dir="$(pwd)"
script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
config_file="${script_dir}/config.yml"
stages=()
dry_run="FALSE"
tmp_dir="$(mktemp -d -p "${script_dir}")"
commands=()

function usage() {
  echo "Usage: ${script_name} (-v|--version)"
  echo "   or: ${script_name} (-h|--help)"
  echo "   or: ${script_name} (install/uninstall) (-c|--component <component>) [options]"
  echo "   or: ${script_name} (info) [options]"
  echo ""
  echo "install/uninstall components:"
  echo "-c, --component        one or more of all/infra/platform/app, pass arg multiple times for more than one"
  echo ""
  echo "install/uninstall options:"
  echo "-f, --config-file      path to file containing config overrides, defaults to config.yml"
  echo "-i, --skip-infra       skip install/uninstall of infra component"
  echo "-p, --skip-platform    skip install/uninstall of platform component"
  echo "-a, --skip-app         skip install/uninstall of app component"
  echo "-d, --dry-run          don't make any changes, instead, try to predict some of the changes that may occur"
  echo "-h, --help             provide usage information"
  echo ""
  echo "info options:"
  echo "-f, --config-file      path to file containing config overrides, defaults to config.yml"
  echo "-h, --help             provide usage information"
}

function execute() {
  validate_args "${@}"
  process_args "${@}"
}

function validate_args() {
  local _args _all_good _valid_args _options _short_options _config_files _components _sub_commands _valid_sub_commands _valid_components _component
  _args=("${@}")
  _all_good=0
  _valid_args=$(getopt -q -o c:f:ipadvh --long component:,config-file:,skip-infra,skip-platform,skip-app,dry-run,version,help -- "${_args[@]}")
  _all_good=$(( _all_good + $? ))
  if [[ _all_good -gt 0 ]]; then
    echo "Invalid usage: ${_args[*]}"
  else
    eval set -- "${_valid_args}"
    _options=()
    _short_options=()
    _config_files=()
    _components=()
    while true; do
      case "${1}" in
        -f | --config-file) _options+=("${1}"); _short_options+=("-f"); shift; _options+=("${1}"); _config_files+=("${exec_dir}/${1}"); shift; ;;
        -c | --component) _options+=("${1}"); _short_options+=("-c"); shift; _options+=("${1}"); _components+=("${1}"); shift; ;;
        -i | --skip-infra) _options+=("${1}"); _short_options+=("-i"); shift; ;;
        -p | --skip-platform) _options+=("${1}"); _short_options+=("-p"); shift; ;;
        -a | --skip-app) _options+=("${1}"); _short_options+=("-a"); shift; ;;
        -d | --dry-run) _options+=("${1}"); _short_options+=("-d"); shift; ;;
        -h | --help) _options+=("${1}"); _short_options+=("-h"); shift; ;;
        -v | --version) _options+=("${1}"); _short_options+=("-v"); shift; ;;
        --) shift; break ;;
      esac
    done
    IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
    IFS=" " read -r -a _config_files <<< "$(de_dupe_elements "${_config_files[@]}")"
    IFS=" " read -r -a _components <<< "$(de_dupe_elements "${_components[@]}")"
    _sub_commands=()
    while [[ -n "${1}" ]]; do
      _sub_commands+=("${1}")
      shift
    done
    _valid_sub_commands=()
    _valid_sub_commands+=('info')
    _valid_sub_commands+=('install')
    _valid_sub_commands+=('uninstall')
    _install_uninstall_sub_commands=()
    _install_uninstall_sub_commands+=('install')
    _install_uninstall_sub_commands+=('uninstall')
    _valid_components=()
    _valid_components+=('all')
    _valid_components+=('infra')
    _valid_components+=('platform')
    _valid_components+=('app')
    if [[ "${#_sub_commands[@]}" -gt 1 ]]; then
      echo "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 1 ]] && ! contains_element "${_sub_commands[0]}" "${_valid_sub_commands[@]}"; then
      echo "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 1 ]] && [[ "${_sub_commands[0]}" == 'info' ]] && ! contains_element "-h" "${_short_options[@]}" && ! getopt -q -o f:h --long config-file:,help -- "${_args[@]}" &> /dev/null; then
      echo "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 1 ]] && contains_element "${_sub_commands[0]}" "${_install_uninstall_sub_commands[@]}" && ! contains_element "-h" "${_short_options[@]}" && ! getopt -q -o c:f:ipadh --long component:,config-file:,skip-infra,skip-platform,skip-app,dry-run,help -- "${_args[@]}" &> /dev/null; then
      echo "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 0 ]] && ! getopt -q -o vh --long version,help -- "${_args[@]}" &> /dev/null; then
      echo "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 1 ]] && ! contains_element "-h" "${_short_options[@]}"; then
      if contains_element "${_sub_commands[0]}" "${_install_uninstall_sub_commands[@]}" && [[ "${#_components[@]}" -eq 0 ]] ; then
        echo "Please specify component from: all/infra/platform/app"
        ((_all_good++))
      else
        for _component in "${_components[@]}"
        do
          if ! contains_element "${_component}" "${_valid_components[@]}"; then
            echo "Invalid component provided: ${_component}"
            ((_all_good++))
          fi
        done
      fi
      if contains_element "-f" "${_short_options[@]}" && [[ "${#_config_files[@]}" -gt 1 ]]; then
        echo "Multiple config-files provided: ${_config_files[*]}"
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
  local _args _valid_args _short_options _config_files _components _sub_commands
  _args=("${@}")
  _valid_args=$(getopt -q -o c:f:ipadvh --long component:,config-file:,skip-infra,skip-platform,skip-app,dry-run,version,help -- "${_args[@]}")
  eval set -- "${_valid_args}"
  _short_options=()
  _config_files=()
  _components=()
  while true; do
    case "${1}" in
      -f | --config-file) _options+=("${1}"); _short_options+=("-f"); shift; _config_files+=("${exec_dir}/${1}"); shift; ;;
      -c | --component) _options+=("${1}"); _short_options+=("-c"); shift; _components+=("${1}"); shift; ;;
      -i | --skip-infra) _options+=("${1}"); _short_options+=("-i"); shift; ;;
      -p | --skip-platform) _options+=("${1}"); _short_options+=("-p"); shift; ;;
      -a | --skip-app) _options+=("${1}"); _short_options+=("-a"); shift; ;;
      -d | --dry-run) _options+=("${1}"); _short_options+=("-d"); dry_run="TRUE"; shift; ;;
      -h | --help) _options+=("${1}"); _short_options+=("-h"); shift; ;;
      -v | --version) _options+=("${1}"); _short_options+=("-v"); shift; ;;
      --) shift; break ;;
    esac
  done
  IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
  IFS=" " read -r -a _config_files <<< "$(de_dupe_elements "${_config_files[@]}")"
  IFS=" " read -r -a _components <<< "$(de_dupe_elements "${_components[@]}")"
  _sub_commands=()
  while [[ -n "${1}" ]]; do
    _sub_commands+=("${1}")
    shift
  done
  if [[ "${#_short_options[@]}" -eq 0 ]]; then
    commands+=('usage')
  elif contains_element "-h" "${_short_options[@]}"; then
    commands+=('usage')
  elif [[ "${#_short_options[@]}" -eq 1 ]] && contains_element "-v" "${_short_options[@]}"; then
    commands+=('print_version')
  else
    if [[ "${#_config_files[@]}" -eq 1 ]]; then
      config_file="${_config_files[0]}"
    fi
    if (contains_element "all" "${_components[@]}" || contains_element "infra" "${_components[@]}") && ! contains_element "-i" "${_short_options[@]}" ; then
      stages+=('infra')
    fi
    if (contains_element "all" "${_components[@]}" || contains_element "platform" "${_components[@]}") && ! contains_element "-p" "${_short_options[@]}" ; then
      stages+=('platform')
    fi
    if (contains_element "all" "${_components[@]}" || contains_element "app" "${_components[@]}") && ! contains_element "-a" "${_short_options[@]}" ; then
      stages+=('app')
    fi
    case "${_sub_commands[0]}" in
      info)
        commands+=('verify_pre_requisites')
        commands+=('activate_venv')
        commands+=('init')
        commands+=('output')
        ;;
      install)
        commands+=('verify_pre_requisites')
        commands+=('activate_venv')
        commands+=('init')
        commands+=('install')
        commands+=('output')
        ;;
      uninstall)
        commands+=('verify_pre_requisites')
        commands+=('activate_venv')
        commands+=('init')
        commands+=('uninstall')
        ;;
    esac
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
  verify_privilege_escalation
  _all_good=$(( _all_good + $? ))
  set_locale_utf8
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

function verify_privilege_escalation() {
  if [[ "${EUID}" -ne 0 ]] && ! sudo -n true &> /dev/null; then
    echo "Current user is neither root, nor has passwordless sudo ability"
    return 1
  else
    return 0
  fi
}

function set_locale_utf8() {
    sudo bash -c 'echo -e "LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8" > /etc/default/locale'
    sudo update-locale
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
  local _tmp_init_dir _config_yml _infra_yml _tf_backend_json _tf_variables_json _uncommented_config_file _infra_vars_yml _platform_vars_yml _app_vars_yml _name
  echo "preparing artifacts"
  switch_to_script_dir

  _tmp_init_dir="${tmp_dir}/init"
  mkdir -p "${_tmp_init_dir}"
  _config_yml="${_tmp_init_dir}/config.yml"
  _infra_yml="${_tmp_init_dir}/infra.yml"
  _tf_backend_json="${_tmp_init_dir}/tf-backend.json"
  _tf_variables_json="${_tmp_init_dir}/tf-variables.json"
  _uncommented_config_file="${_tmp_init_dir}/uncommented_config.yml"
  _infra_vars_yml="${_tmp_init_dir}/infra_vars.yml"
  _platform_vars_yml="${_tmp_init_dir}/platform_vars.yml"
  _app_vars_yml="${_tmp_init_dir}/app_vars.yml"

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

  # prepare _infra_vars_yml
  yq eval '.spec.infra | del(.backend) | del(.provider)' "${_config_yml}" > "${_infra_vars_yml}"

  # prepare _platform_vars_yml
  yq eval '.spec.platform' "${_config_yml}" > "${_platform_vars_yml}"

  # prepare _app_vars_yml
  yq eval '.spec.app' "${_config_yml}" > "${_app_vars_yml}"

  # install ansible requirements
  if [[ -f ansible-requirements.yml ]]; then
    ansible-galaxy install -r ansible-requirements.yml &> /dev/null
  fi

  cp -r iac-ref iac
  cp "${_tf_backend_json}" iac/tf-backend.json
  cp "${_tf_variables_json}" iac/tf-variables.json
  cp "${_infra_vars_yml}" playbooks/infra-vars.yml
  cp "${_platform_vars_yml}" playbooks/platform-vars.yml
  cp "${_app_vars_yml}" playbooks/app-vars.yml
}

function install() {
  if contains_element "infra" "${stages[@]}"; then
    apply_tf_shape
    if ! extract_inventory || ! check_inventory; then
      exit 1
    else
      install_plays "infra"
      exit_if_not_ok "${?}"
    fi
  elif contains_element "platform" "${stages[@]}" || contains_element "app" "${stages[@]}"; then
    if ! extract_inventory || ! check_inventory; then
      exit 1
    fi
  fi
  if contains_element "platform" "${stages[@]}"; then
    install_plays "platform"
    exit_if_not_ok "${?}"
  fi
  if contains_element "app" "${stages[@]}"; then
    install_plays "app"
    exit_if_not_ok "${?}"
  fi
}

function uninstall() {
  if contains_element "infra" "${stages[@]}"; then
    if extract_inventory && check_inventory; then
      uninstall_plays "infra"
    fi
    destroy_tf_shape
  else
    if extract_inventory && check_inventory; then
      if contains_element "app" "${stages[@]}"; then
        uninstall_plays "app"
        exit_if_not_ok "${?}"
      fi
      if contains_element "platform" "${stages[@]}"; then
        uninstall_plays "platform"
        exit_if_not_ok "${?}"
      fi
    else
      exit 1
    fi
  fi
}

function output() {
  switch_to_script_dir
  terraform -chdir="iac" init -reconfigure -backend-config=tf-backend.json > /dev/null
  echo ""
  echo "==========================================================================================="
  terraform -chdir="iac" output -json | jq -r '.info.value // {} | del(..|nulls)' | yq -P
  echo "==========================================================================================="
}

function apply_tf_shape() {
  echo "applying TF shape"
  abort_option
  switch_to_script_dir
  terraform -chdir="iac" init -reconfigure -backend-config=tf-backend.json > /dev/null
  terraform -chdir="iac" plan -compact-warnings -out=tf-plan -var-file=tf-variables.json -detailed-exitcode
  _exit_code=$?
  if [[ "${_exit_code}" == "1" ]]; then
    echo "failed to determine IaC changes"
    exit 1
  fi
  if [[ "${dry_run}" == "FALSE" ]] && [[ "${_exit_code}" == "2" ]] && [[ -f "iac/tf-plan" ]]; then
    terraform -chdir="iac" apply tf-plan || exit 1
  fi
}

function destroy_tf_shape() {
  echo "destroying TF shape"
  abort_option
  switch_to_script_dir
  terraform -chdir="iac" init -reconfigure -backend-config=tf-backend.json > /dev/null
  terraform -chdir="iac" plan -compact-warnings -out=tf-plan -var-file=tf-variables.json -destroy -detailed-exitcode
  _exit_code=$?
  if [[ "${_exit_code}" == "1" ]]; then
    echo "failed to determine IaC changes"
    exit 1
  fi
  if [[ "${dry_run}" == "FALSE" ]] && [[ "${_exit_code}" == "2" ]] && [[ -f "iac/tf-plan" ]]; then
    terraform -chdir="iac" apply tf-plan
  fi
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
    rm playbooks/iac-vars.yml &> /dev/null || true
    return 1
  else
    terraform -chdir="iac" output -json | jq -r '.hosts.value' > inventory.yml
    terraform -chdir="iac" output -json | jq -r '.cns_clusters.value // {} | keys' > cns-host-groups.json
    terraform -chdir="iac" output -json | jq -r '.playbook_configs.value // {} | {iac: .}' | yq -P > playbooks/iac-vars.yml
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

function install_plays() {
  local _stage _task
  _stage="${1}"
  echo "installing ${_stage} plays"
  abort_option
  switch_to_script_dir
  for _task in $(yq eval ".tasks" -o json "${_stage}-tasks.yml" | jq -r '. | map(.name)[]'); do
    if ! run_play "${_stage}" "${_task}" "present"; then
      return 1
    fi
  done
}

function uninstall_plays() {
  local _stage _task
  _stage="${1}"
  echo "uninstalling ${_stage} plays"
  abort_option
  switch_to_script_dir
  for _task in $(yq eval ".tasks" -o json "${_stage}-tasks.yml" | jq -r '. | reverse | map(.name)[]'); do
    if ! run_play "${_stage}" "${_task}" "absent"; then
      return 1
    fi
  done
}

function run_play() {
  local _stage _task _state _tmp_task_dir _play _when_dry_run _task_vars_file
  local _expression_args _condition_expression _condition_file
  local _task_config_args _task_config_file _config_file_counter _task_config_source _task_config_destination
  local _for_each_expression _for_each_file _each_vars_file _expression_args_for_each
  local _task_targets _target_file _target
  _stage="${1}"
  _task="${2}"
  _state="${3}"
  _tmp_task_dir="${tmp_dir}/${_stage}-tasks/${_task}"
  mkdir -p "${_tmp_task_dir}"
  _play="$(yq eval ".tasks" -o json "${_stage}-tasks.yml" | jq --arg task "${_task}" -r '. | map(select(.name == $task))[0].play')"
  _when_dry_run="$(yq eval ".tasks" -o json "${_stage}-tasks.yml" | jq --arg task "${_task}" -r '. | map(select(.name == $task))[0].when_dry_run // "dry-run"')"
  _task_vars_file="${_tmp_task_dir}/vars.yml"
  yq eval ".tasks" -o json "${_stage}-tasks.yml" | \
    jq --arg task "${_task}" -r '. | map(select(.name == $task))[0].vars // {} | {task_vars: .}' | \
    yq -P > "${_task_vars_file}"
  if [[ "${_state}" == "present" ]]; then
    echo "applying task: ${_task}"
  fi
  if [[ "${_state}" == "absent" ]]; then
    echo "reverting task: ${_task}"
  fi
  echo ""
  _expression_args=()
  _expression_args+=("-e")
  _expression_args+=("@${_task_vars_file}")
  _expression_args+=("-e")
  _expression_args+=("@playbooks/${_stage}-vars.yml")
  _expression_args+=("-e")
  _expression_args+=("@playbooks/iac-vars.yml")
  _expression_args+=("-e")
  _expression_args+=("dist_dir=${script_dir}")
  _expression_args+=("-e")
  _expression_args+=("state=${_state}")
  _expression_args+=("-e")
  _expression_args+=("tmp_task_dir=${_tmp_task_dir}")
  _expression_args+=("-e")
  _expression_args+=("dry_run_mode=${dry_run,,}")
  _condition_expression="$(yq eval ".tasks" -o json "${_stage}-tasks.yml" | jq --arg task "${_task}" -r '. | map(select(.name == $task))[0].condition // ""')"
  _condition_file="${_tmp_task_dir}/condition.txt"
  if [[ -n "${_condition_expression}" ]]; then
    if ! output_jinja2_expression "${_condition_expression}" "${_condition_file}" "txt" "${_expression_args[@]}"; then
      return 1
    fi
    if [[ "$(tr '[:upper:]' '[:lower:]' < "${_condition_file}")" != "true" ]]; then
      echo "skipping task: ${_task} since condition: ${_condition_expression} did not evaluate to true"
      return 0
    fi
  fi
  _task_config_args=()
  _task_config_file="${_tmp_task_dir}/config.yml"
  yq eval ".tasks" -o json "${_stage}-tasks.yml" | \
    jq --arg task "${_task}" -r '. | map(select(.name == $task))[0].config // {} | {task_config: .}' | \
    yq -P > "${_task_config_file}"
  _task_config_args+=("-e")
  _task_config_args+=("@${_task_config_file}")
  mkdir -p "${_tmp_task_dir}/config-files"
  _config_file_counter=0
  while read -r _config_file; do
    if [[ -n "${_config_file}" ]]; then
      ((_config_file_counter++))
      _task_config_source="${script_dir}/config-files/${_config_file}"
      _task_config_destination="${_tmp_task_dir}/config-files/config-${_config_file_counter}.yml"
      if ! ANSIBLE_JINJA2_NATIVE=true ansible-playbook \
          -c local \
          -i localhost, \
          -e config_source="${_task_config_source}" \
          -e config_destination="${_task_config_destination}" \
          "${_expression_args[@]}" \
          playbooks/copy-task-config.yml &> /dev/null; then
        echo "could not copy config file: ${_config_file}"
        return 1
      fi
      _task_config_args+=("-e")
      _task_config_args+=("@${_task_config_destination}")
    fi
  done <<< "$(yq eval ".tasks" -o json "${_stage}-tasks.yml" | jq --arg task "${_task}" -r '. | map(select(.name == $task))[0].config_files // [] | .[]')"
  _for_each_expression="$(yq eval ".tasks" -o json "${_stage}-tasks.yml" | jq --arg task "${_task}" -r '. | map(select(.name == $task))[0].for_each // ""')"
  _for_each_file="${_tmp_task_dir}/each.yml"
  if [[ -n "${_for_each_expression}" ]]; then
    if ! output_jinja2_expression "${_for_each_expression}" "${_for_each_file}" "yaml" "${_expression_args[@]}"; then
      return 1
    fi
  else
    jq -n '{default: {}}' | yq -P > "${_for_each_file}"
  fi
  for _each_key in $(yq eval 'keys' "${_for_each_file}" -o json | jq -r '.[]'); do
    _each_vars_file="${_tmp_task_dir}/each-vars.yml"
    yq eval ".${_each_key}" "${_for_each_file}" -o json | jq --arg key "${_each_key}" -r '{task_each_vars: {key: $key, value: .}}' | yq -P > "${_each_vars_file}"
    _expression_args_for_each=("${_expression_args[@]}")
    _expression_args_for_each+=("-e")
    _expression_args_for_each+=("@${_each_vars_file}")
    _task_targets=()
    while read -r _target_expression; do
      if [[ -n "${_target_expression}" ]]; then
        _target_file="${_tmp_task_dir}/target"
        if ! output_jinja2_expression "${_target_expression}" "${_target_file}" "yaml" "${_expression_args_for_each[@]}"; then
          return 1
        else
          _target="$(cat "${_target_file}")"
          _task_targets+=("${_target}")
        fi
      fi
    done <<< "$(yq eval ".tasks" -o json "${_stage}-tasks.yml" | jq --arg task "${_task}" -r '. | map(select(.name == $task))[0].targets // [] | .[]')"
    if [[ "${#_task_targets[*]}" -eq 0 ]]; then
      _task_targets+=("all")
    fi
    for _task_target in "${_task_targets[@]}"; do
      if [[ "${dry_run}" == "TRUE" ]] && [[ "${_when_dry_run}" == "dry-run" ]]; then
        ANSIBLE_JINJA2_NATIVE=true ansible-playbook \
          --check \
          -i inventory.yml \
          -l "localhost:${_task_target}" \
          "${_task_config_args[@]}" \
          "${_expression_args_for_each[@]}" \
          "playbooks/${_play}.yml"
      elif [[ "${dry_run}" != "TRUE" ]] || [[ "${_when_dry_run}" == "run" ]]; then
        if ! ANSIBLE_JINJA2_NATIVE=true ansible-playbook \
            -i inventory.yml \
            -l "localhost:${_task_target}" \
            "${_task_config_args[@]}" \
            "${_expression_args_for_each[@]}" \
            "playbooks/${_play}.yml"; then
          return 1
        fi
      else
        echo "skipping task: ${_task} since dry-run: ${dry_run,,} and task is marked: ${_when_dry_run,,} when dry-run is true"
      fi
    done
  done
}

function output_jinja2_expression() {
  local _expression _output_file _output_format
  _expression="${1}"
  _output_file="${2}"
  _output_format="${3}"
  if ! ANSIBLE_JINJA2_NATIVE=true ansible-playbook \
      -c local \
      -i localhost, \
      -e expression="${_expression}" \
      -e output_file="${_output_file}" \
      -e output_format="${_output_format}" \
      "${@:4}" \
      playbooks/output-jinja2-expression-to-file.yml &> /dev/null; then
    echo "could not evaluate expression: ${_expression}"
    return 1
  fi
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
      playbooks/process-user-config.yml > /dev/null 2> /dev/stderr; then
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

