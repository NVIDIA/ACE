#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

schema_version="0.0.10"
script_name="${0}"
exec_dir="$(pwd)"
script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
start_time="$(date)"
start_epoch="$(date +%s)"
log_file_path="${script_dir}/logs/$(basename "${script_name}" | sed -e 's/\./-/g' -e 's/_/-/g')-${start_epoch}.log"
config_file="${script_dir}/config.yml"
tf_binary_name='tofu'
stages=()
dry_run="FALSE"
tmp_dir="$(mktemp -d -p "${script_dir}")"
csp=""
commands=()
cleanup_commands=()
cleanup_commands+=('cleanup_tmp_dir')
cleanup_commands+=('publish_log_file_name')

function initialize_logging() {
  mkdir -p "$( dirname -- "${log_file_path}")"
  exec {log_file}>"${log_file_path}"
  exec {output_suppress}>/dev/null
  exec {output_info}> >(tee -a "/dev/fd/$log_file")
  exec {output_debug_off}> >(tee -a "/dev/fd/$log_file" > /dev/null)
  exec {output_debug_on}> >(tee -a "/dev/fd/$log_file")
  exec {output_debug}>&$output_debug_off
  exec 1>&$log_file
  exec 2>&$log_file
  printf '%*s\n' "$(tput cols)" ' '  | tr ' ' '='
  echo "Command: ${script_name} ${*}"
  echo "Start time: ${start_time}"
  printf '%*s\n' "$(tput cols)" ' '  | tr ' ' '-'
  set -x
}

function blank_info_line() {
  echo "" >&$output_info
}

function terminal_width() {
  tput cols || echo "100"
}

function open_info_banner() {
  printf '%*s\n' "$(terminal_width)" ' '  | tr ' ' '=' >&$output_info
}

function close_info_banner() {
  printf '%*s\n' "$(terminal_width)" ' '  | tr ' ' '-' >&$output_info
}

function info_out() {
  local _message
  _message="${1}"
  echo "[INFO]  ${_message}" >&$output_info
}

function open_debug_banner() {
  printf '%*s\n' "$(terminal_width)" ' '  | tr ' ' '=' >&$output_debug
}

function close_debug_banner() {
  printf '%*s\n' "$(terminal_width)" ' '  | tr ' ' '-' >&$output_debug
}

function debug_out() {
  local _message
  _message="${1}"
  echo "[DEBUG] ${_message}" >&$output_debug
}

function usage() {
  open_info_banner
  info_out "Usage: ${script_name} (-v|--version)"
  info_out "   or: ${script_name} (-h|--help)"
  info_out "   or: ${script_name} (install/uninstall) (-c|--component <component>) [options]"
  info_out "   or: ${script_name} (force-destroy) [options]"
  info_out "   or: ${script_name} (info) [options]"
  blank_info_line
  info_out "install/uninstall components:"
  info_out "-c, --component        one or more of all/infra/platform/app, pass arg multiple times for more than one"
  blank_info_line
  info_out "install/uninstall options:"
  info_out "-f, --config-file      path to file containing config overrides, defaults to config.yml"
  info_out "-t, --tf-binary        the IaC binary to use, can be tofu or terraform, defaults to tofu"
  info_out "-i, --skip-infra       skip install/uninstall of infra component"
  info_out "-p, --skip-platform    skip install/uninstall of platform component"
  info_out "-a, --skip-app         skip install/uninstall of app component"
  info_out "-d, --dry-run          don't make any changes, instead, try to predict some of the changes that may occur"
  info_out "-h, --help             provide usage information"
  info_out "-x, --debug            output additional information in order to debug issues"
  blank_info_line
  info_out "force-destroy options:"
  info_out "-f, --config-file      path to file containing config overrides, defaults to config.yml"
  info_out "-t, --tf-binary        the IaC binary to use, can be tofu or terraform, defaults to tofu"
  info_out "-h, --help             provide usage information"
  info_out "-x, --debug            output additional information in order to debug issues"
  blank_info_line
  info_out "info options:"
  info_out "-f, --config-file      path to file containing config overrides, defaults to config.yml"
  info_out "-t, --tf-binary        the IaC binary to use, can be tofu or terraform, defaults to tofu"
  info_out "-h, --help             provide usage information"
  info_out "-x, --debug            output additional information in order to debug issues"
  close_info_banner
}

function execute() {
  validate_args "${@}"
  process_args "${@}"
}

function absolute_path() {
  local _base_directory _path _absolue_path
  _base_directory="${1}"
  _path="${2}"
  if [[ ${_path:0:1} == '/' ]]; then
    echo "${_path}"
  else
    echo "${_base_directory}/${_path}"
  fi
}

function validate_args() {
  local _args _all_good _valid_args _options _short_options _components _config_files _tf_binaries
  local _sub_commands _valid_sub_commands _install_uninstall_sub_commands _valid_components _valid_tf_binaries
  local _tf_binary _component
  _args=("${@}")
  _all_good=0
  _valid_args=$(getopt -q -o c:f:t:ipadvhx --long component:,config-file:,tf-binary:,skip-infra,skip-platform,skip-app,dry-run,version,help,debug -- "${_args[@]}")
  _all_good=$(( _all_good + $? ))
  if [[ _all_good -gt 0 ]]; then
    info_out "Invalid usage: ${_args[*]}"
  else
    eval set -- "${_valid_args}"
    _options=()
    _short_options=()
    _components=()
    _config_files=()
    _tf_binaries=()
    while true; do
      case "${1}" in
        -c | --component) _options+=("${1}"); _short_options+=("-c"); shift; _options+=("${1}"); _components+=("${1}"); shift; ;;
        -f | --config-file) _options+=("${1}"); _short_options+=("-f"); shift; _options+=("${1}"); _config_files+=("$(absolute_path "${exec_dir}" "${1}")"); shift; ;;
        -t | --tf-binary) _options+=("${1}"); _short_options+=("-t"); shift; _options+=("${1}"); _tf_binaries+=("${1}"); shift; ;;
        -i | --skip-infra) _options+=("${1}"); _short_options+=("-i"); shift; ;;
        -p | --skip-platform) _options+=("${1}"); _short_options+=("-p"); shift; ;;
        -a | --skip-app) _options+=("${1}"); _short_options+=("-a"); shift; ;;
        -d | --dry-run) _options+=("${1}"); _short_options+=("-d"); shift; ;;
        -v | --version) _options+=("${1}"); _short_options+=("-v"); shift; ;;
        -h | --help) _options+=("${1}"); _short_options+=("-h"); shift; ;;
        -x | --debug) _options+=("${1}"); _short_options+=("-x"); shift; ;;
        --) shift; break ;;
      esac
    done
    IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
    IFS=" " read -r -a _components <<< "$(de_dupe_elements "${_components[@]}")"
    IFS=" " read -r -a _config_files <<< "$(de_dupe_elements "${_config_files[@]}")"
    IFS=" " read -r -a _tf_binaries <<< "$(de_dupe_elements "${_tf_binaries[@]}")"
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
    _valid_sub_commands+=('force-destroy')
    _valid_tf_binaries=()
    _valid_tf_binaries+=('tofu')
    _valid_tf_binaries+=('terraform')
    if [[ "${#_sub_commands[@]}" -gt 1 ]]; then
      info_out "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 1 ]] && ! contains_element "${_sub_commands[0]}" "${_valid_sub_commands[@]}"; then
      info_out "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 1 ]] && [[ "${_sub_commands[0]}" == 'info' ]] && ! contains_element "-h" "${_short_options[@]}" && ! getopt -q -o f:t:hx --long config-file:,tf-binary:,help,debug -- "${_args[@]}"; then
      info_out "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 1 ]] && [[ "${_sub_commands[0]}" == 'force-destroy' ]] && ! contains_element "-h" "${_short_options[@]}" && ! getopt -q -o f:t:hx --long config-file:,tf-binary:,help,debug -- "${_args[@]}"; then
      info_out "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 1 ]] && contains_element "${_sub_commands[0]}" "${_install_uninstall_sub_commands[@]}" && ! contains_element "-h" "${_short_options[@]}" && ! getopt -q -o c:f:t:ipadhx --long component:,config-file:,tf-binary:,skip-infra,skip-platform,skip-app,dry-run,help,debug -- "${_args[@]}"; then
      info_out "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 0 ]] && ! getopt -q -o vh --long version,help -- "${_args[@]}"; then
      info_out "Invalid usage: ${_args[*]}"
      ((_all_good++))
    elif [[ "${#_sub_commands[@]}" -eq 1 ]] && ! contains_element "-h" "${_short_options[@]}"; then
      if contains_element "-t" "${_short_options[@]}" && [[ "${#_tf_binaries[@]}" -gt 1 ]]; then
        info_out "Multiple tf-binaries provided: ${_tf_binaries[*]}"
        ((_all_good++))
      fi
      for _tf_binary in "${_tf_binaries[@]}"
      do
        if ! contains_element "${_tf_binary}" "${_valid_tf_binaries[@]}"; then
          info_out "Invalid tf-binary provided: ${_tf_binary}"
          ((_all_good++))
        fi
      done
      if contains_element "${_sub_commands[0]}" "${_install_uninstall_sub_commands[@]}" && [[ "${#_components[@]}" -eq 0 ]] ; then
        info_out "Please specify component from: all/infra/platform/app"
        ((_all_good++))
      else
        for _component in "${_components[@]}"
        do
          if ! contains_element "${_component}" "${_valid_components[@]}"; then
            info_out "Invalid component provided: ${_component}"
            ((_all_good++))
          fi
        done
      fi
      if contains_element "-f" "${_short_options[@]}" && [[ "${#_config_files[@]}" -gt 1 ]]; then
        info_out "Multiple config-files provided: ${_config_files[*]}"
        ((_all_good++))
      fi
    fi
  fi
  if [[ _all_good -gt 0 ]]; then
    blank_info_line
    usage
    exit 1
  fi
}

function process_args() {
  local _args _valid_args _short_options _components _config_files _tf_binaries _sub_commands
  _args=("${@}")
  _valid_args=$(getopt -q -o c:f:t:ipadvhx --long component:,config-file:,tf-binary:,skip-infra,skip-platform,skip-app,dry-run,version,help,debug -- "${_args[@]}")
  eval set -- "${_valid_args}"
  _short_options=()
  _components=()
  _config_files=()
  _tf_binaries=()
  while true; do
    case "${1}" in
      -c | --component) _options+=("${1}"); _short_options+=("-c"); shift; _components+=("${1}"); shift; ;;
      -f | --config-file) _options+=("${1}"); _short_options+=("-f"); shift; _config_files+=("$(absolute_path "${exec_dir}" "${1}")"); shift; ;;
      -t | --tf-binary) _options+=("${1}"); _short_options+=("-t"); shift; _tf_binaries+=("${1}"); shift; ;;
      -i | --skip-infra) _options+=("${1}"); _short_options+=("-i"); shift; ;;
      -p | --skip-platform) _options+=("${1}"); _short_options+=("-p"); shift; ;;
      -a | --skip-app) _options+=("${1}"); _short_options+=("-a"); shift; ;;
      -d | --dry-run) _options+=("${1}"); _short_options+=("-d"); dry_run="TRUE"; shift; ;;
      -v | --version) _options+=("${1}"); _short_options+=("-v"); shift; ;;
      -h | --help) _options+=("${1}"); _short_options+=("-h"); shift; ;;
      -x | --debug) _options+=("${1}"); _short_options+=("-x"); shift; ;;
      --) shift; break ;;
    esac
  done
  IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
  IFS=" " read -r -a _components <<< "$(de_dupe_elements "${_components[@]}")"
  IFS=" " read -r -a _config_files <<< "$(de_dupe_elements "${_config_files[@]}")"
  IFS=" " read -r -a _tf_binaries <<< "$(de_dupe_elements "${_tf_binaries[@]}")"
  _sub_commands=()
  while [[ -n "${1}" ]]; do
    _sub_commands+=("${1}")
    shift
  done
  if [[ "${#_short_options[@]}" -eq 0 ]] && [[ "${#_sub_commands[@]}" -eq 0 ]]; then
    commands+=('usage')
  elif contains_element "-h" "${_short_options[@]}"; then
    commands+=('usage')
  elif [[ "${#_short_options[@]}" -eq 1 ]] && contains_element "-v" "${_short_options[@]}"; then
    commands+=('print_version')
  else
    if [[ "${#_config_files[@]}" -eq 1 ]]; then
      config_file="${_config_files[0]}"
    fi
    if [[ "${#_tf_binaries[@]}" -eq 1 ]]; then
      tf_binary_name="${_tf_binaries[0]}"
    fi
    if contains_element "-x" "${_short_options[@]}" ; then
      exec {output_debug}>&$output_debug_on
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
      force-destroy)
        commands+=('verify_pre_requisites')
        commands+=('activate_venv')
        commands+=('init')
        commands+=('force_destroy')
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
  info_out "Version: ${schema_version}"
}

function prompt_acceptance() {
  local _confirm
  read -r -p "Would you like to ${1}? (y/n): " _confirm 2>&$output_info
  is_yes "${_confirm}"
  return "${?}"
}

function verify_pre_requisites() {
  local _install_or_update_requirement _all_good _requirements _requirement
  _install_or_update_requirement="$(host_supports_install_or_update_of_requirements)"
  _all_good=0
  verify_config
  _all_good=$(( _all_good + $? ))
  verify_privilege_escalation
  _all_good=$(( _all_good + $? ))
  _requirements=()
  _requirements+=('jq')
  _requirements+=("$(tf_binary)")
  _requirements+=('python3')
  _requirements+=('python3-venv')
  _requirements+=('python3-pip')
  for _requirement in "${_requirements[@]}"
  do
    verify_requirement "${_requirement}" "${_install_or_update_requirement}"
    _all_good=$(( _all_good + $? ))
  done
  if [[ _all_good -gt 0 ]]; then
    info_out "One or more pre-requisites were not met"
    exit 1
  fi
}

function verify_config() {
  if [[ ! -f "${config_file}" ]]; then
    info_out "Config file (${config_file}) not found"
    info_out "Please use ${script_dir}/config-template.yml to create the ${config_file}"
    return 1
  fi
}

function verify_privilege_escalation() {
  if [[ "${EUID}" -ne 0 ]] && ! sudo -n true; then
    info_out "Current user is neither root, nor has passwordless sudo ability"
    return 1
  else
    return 0
  fi
}

function requirement_present() {
  local _requirement
  _requirement="${1}"
  case "${_requirement}" in
    jq | terraform | tofu)
      hash "${_requirement}"
      return "${?}"
      ;;
    python3 | python3-venv | python3-pip)
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
      jq --version | cut -d '-' -f 2 || echo ""
      ;;
    terraform)
      terraform --version | head -n 1 | awk '{print $2}' | tr -d 'v' || echo ""
      ;;
    tofu)
      tofu --version | head -n 1 | awk '{print $2}' | tr -d 'v' || echo ""
      ;;
    python3 | python3-venv | python3-pip)
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
    terraform)
      echo '1.5.7'
      ;;
    tofu)
      echo '1.9.0'
      ;;
    python3 | python3-venv)
      echo '3.9.0'
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
    *)
      echo ""
      ;;
  esac
}

function requirement_preferred_version_amd64_ubuntu_22.04() {
  local _requirement
  _requirement="${1}"
  case "${_requirement}" in
    jq)
      echo '1.6-*'
      ;;
    terraform)
      echo '1.5.7-*'
      ;;
    tofu)
      echo '1.9.0'
      ;;
    python3 | python3-venv)
      echo '3.10.6-*'
      ;;
    python3-pip)
      echo '22.0.2+dfsg-*'
      ;;
    *)
      echo "LATEST"
      ;;
  esac
}

function requirement_preferred_version_amd64_ubuntu_24.04() {
  local _requirement
  _requirement="${1}"
  case "${_requirement}" in
    jq)
      echo '1.7.1-*'
      ;;
    terraform)
      echo '1.5.7-*'
      ;;
    tofu)
      echo '1.9.0'
      ;;
    python3 | python3-venv)
      echo '3.12.3-*'
      ;;
    python3-pip)
      echo '24.0+dfsg-*'
      ;;
    *)
      echo "LATEST"
      ;;
  esac
}

function requirement_preferred_version() {
  local _requirement
  _requirement="${1}"
  "requirement_preferred_version_$(get_cpu_architecture)_$(get_os)_$(get_os_version)" "${_requirement}"
}

function requirement_install_or_update() {
  local _requirement _requirement_version
  _requirement="${1}"
  _requirement_version="${2:-LATEST}"
  case "${_requirement}" in
    jq | terraform | tofu | python3 | python3-venv | python3-pip)
      add_apt_repository "${_requirement}"
      if [[ "${_requirement_version}" != "LATEST" ]]; then
        install_or_update_apt_package "${_requirement}=${_requirement_version}"
      else
        install_or_update_apt_package "${_requirement}"
      fi
      ;;
    *)
      echo "1"
      ;;
  esac
}

function verify_apt_package_present() {
  local _apt_package
  _apt_package="${1}"
  if [[ "$(apt -qq list --installed "${_apt_package}" | wc -l)" -eq 1 ]]; then
    return 0;
  else
    return 1;
  fi
}

function apt_package_version() {
  local _apt_package
  _apt_package="${1}"
  apt show "${_apt_package}" | grep '^Version' | awk '{print $NF}' | awk -F ':' '{print $NF}' | awk -F '[-+]' '{print $1}'
}

function add_apt_repository() {
  local _requirement
  _requirement="${1}"
  case "${_requirement}" in
    terraform)
      debug_out "Adding apt repository for terraform"
      open_debug_banner
      $(privilege_escalation) apt-get install \
        -y gnupg software-properties-common \
        >&$output_debug 2>&1
      wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        $(privilege_escalation) tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        >&$output_suppress 2>&1
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        $(privilege_escalation) tee /etc/apt/sources.list.d/hashicorp.list \
        >&$output_debug 2>&1
      close_debug_banner
      ;;
    tofu)
      debug_out "Adding apt repository for tofu"
      open_debug_banner
      $(privilege_escalation) apt-get install \
        -y gnupg software-properties-common \
        >&$output_debug 2>&1
      $(privilege_escalation) install \
        -m 0755 \
        -d /etc/apt/keyrings \
        >&$output_debug 2>&1
      curl -fsSL https://get.opentofu.org/opentofu.gpg | \
        $(privilege_escalation) tee /etc/apt/keyrings/opentofu.gpg \
        >&$output_suppress 2>&1
      curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | \
        $(privilege_escalation) gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg \
        >&$output_suppress 2>&1
      $(privilege_escalation) chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg \
        >&$output_debug 2>&1
      echo "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | \
        $(privilege_escalation) tee /etc/apt/sources.list.d/opentofu.list \
        >&$output_debug 2>&1
      echo "deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | \
        $(privilege_escalation) tee -a /etc/apt/sources.list.d/opentofu.list \
        >&$output_debug 2>&1
      $(privilege_escalation) chmod a+r /etc/apt/sources.list.d/opentofu.list \
        >&$output_debug 2>&1
      close_debug_banner
      ;;
    *)
      ;;
  esac
}

function install_or_update_apt_package() {
  local _apt_package
  _apt_package="${1}"
  debug_out "Installing apt package: ${_apt_package}"
  open_debug_banner
  $(privilege_escalation) apt update \
    >&$output_debug 2>&1
  $(privilege_escalation) apt-get install "${_apt_package}" -y \
    >&$output_debug 2>&1
  close_debug_banner
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
  if prompt_acceptance "Install/Update ${_requirement}"; then
    _requirement_preferred_version="$(requirement_preferred_version "${_requirement}")"
    info_out "installing ${_requirement}"
    if ! requirement_install_or_update "${_requirement}" "${_requirement_preferred_version}" &> /dev/null; then
      info_out "failed to install ${_requirement}"
    fi
  fi
}

function get_os() {
  grep -iw ID /etc/os-release | awk -F '=' '{print $2}'
}

function get_os_version() {
  grep -iw VERSION_ID /etc/os-release | awk -F '=' '{print $2}' | tr -d '"'
}

function get_cpu_architecture() {
  dpkg --print-architecture
}

function host_supports_install_or_update_of_requirements() {
  case "$(get_cpu_architecture)-$(get_os)-$(get_os_version)" in
    amd64-ubuntu-22.04 | amd64-ubuntu-24.04)
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
  if is_yes "${_attempt_install_or_update}" && verify_privilege_escalation; then
    if ! requirement_present "${_requirement}" || ! verify_min_requirement_version "${_requirement}" || ! verify_max_requirement_version "${_requirement}"; then
      install_or_update_requirement "${_requirement}"
      verify_requirement "${_requirement}" "no"
    fi
  elif ! requirement_present "${_requirement}"; then
    info_out "Requirement ${_requirement} is required"
    return 1
  elif ! verify_min_requirement_version "${_requirement}"; then
    info_out "Requirement ${_requirement} version is $(requirement_version "${_requirement}")"
    if [[ "$(requirement_min_version "${_requirement}")" == "$(requirement_max_version "${_requirement}")" ]]; then
      info_out "Requirement ${_requirement} version should be $(requirement_min_version "${_requirement}")"
    elif [[ -n "$(requirement_max_version "${_requirement}")" ]]; then
      info_out "Requirement ${_requirement} version should be between $(requirement_min_version "${_requirement}") and $(requirement_max_version "${_requirement}")"
    else
      info_out "Requirement ${_requirement} version should be greater than $(requirement_min_version "${_requirement}")"
    fi
    return 1
  elif ! verify_max_requirement_version "${_requirement}"; then
    info_out "Requirement ${_requirement} version is $(requirement_version "${_requirement}")"
    if [[ "$(requirement_max_version "${_requirement}")" == "$(requirement_min_version "${_requirement}")" ]]; then
      info_out "Requirement ${_requirement} version should be $(requirement_max_version "${_requirement}")"
    elif [[ -n "$(requirement_min_version "${_requirement}")" ]]; then
      info_out "Requirement ${_requirement} version should be between $(requirement_min_version "${_requirement}") and $(requirement_max_version "${_requirement}")"
    else
      info_out "Requirement ${_requirement} version should be lesser than $(requirement_max_version "${_requirement}")"
    fi
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

function tf_binary() {
  echo -n "${tf_binary_name}"
}

function exit_if_not_ok() {
  if [[ "${1}" != "0" ]]; then
    exit "${1}"
  fi
}

function deactivate_venv() {
  deactivate || true
}

function activate_venv() {
  deactivate_venv
  python3 -m venv --copies --clear "${tmp_dir}/venv"
  source "${tmp_dir}/venv/bin/activate"
  register_cleanup_command "deactivate_venv"
  debug_out "Installing/Upgrading pip packages"
  open_debug_banner
  pip install --require-virtualenv --requirement requirements.txt >&$output_debug 2>&1
  close_debug_banner
  export LC_ALL="C.UTF-8"
  export LC_CTYPE="C.UTF-8"
  export ANSIBLE_FORCE_COLOR="true"
  export ANSIBLE_JINJA2_NATIVE="true"
  export ANSIBLE_PYTHON_INTERPRETER="auto_silent"
  if ! hash deactivate; then
    info_out "Failed to activate virtualenv"
    exit 1
  fi
}

function abort_option() {
  info_out "CTRL-C to abort"
  sleep 10
}

function switch_to_script_dir() {
  cd "${script_dir}" || exit 1
}

function init() {
  local _tmp_init_dir _config_yml _infra_yml _tf_backend_json _tf_variables_json _uncommented_config_file _infra_vars_yml _platform_vars_yml _app_vars_yml _name
  info_out "Preparing artifacts"
  switch_to_script_dir

  _tmp_init_dir="${tmp_dir}/init"
  mkdir -p "${_tmp_init_dir}"
  _config_yml="${_tmp_init_dir}/config.yml"
  _infra_yml="${_tmp_init_dir}/infra.yml"
  _tf_backend_json="${_tmp_init_dir}/tf-backend.json"
  _tf_variables_json="${_tmp_init_dir}/tf-variables.json"
  _uncommented_config_file="${_tmp_init_dir}/uncommented-config.yml"
  _infra_vars_yml="${_tmp_init_dir}/infra-vars.yml"
  _platform_vars_yml="${_tmp_init_dir}/platform-vars.yml"
  _app_vars_yml="${_tmp_init_dir}/app-vars.yml"

  # prepare _config_yml
  sed '/^[[:space:]]*#/d' "${config_file}" > "${_uncommented_config_file}"
  process_user_config "${_uncommented_config_file}" "${_config_yml}"

  # get _name
  _name="$(yq -r '.name' < "${_config_yml}")"

  # prepare _infra_yml
  yq -y -w 1000 '.spec.infra' < "${_config_yml}" > "${_infra_yml}"

  # prepare _tf_backend_json
  csp="$(yq -r '.csp' < "${_infra_yml}")"
  case "${csp}" in
    aws | azure)
      jq -n \
        --arg name "${_name}" \
        --argjson config "$(yq -r '.backend' < "${_infra_yml}")" \
        '$config * { key: ($name + "/terraform.tfstate") }' > "${_tf_backend_json}"
      ;;
    gcp)
      jq -n \
        --arg name "${_name}" \
        --argjson config "$(yq -r '.backend' < "${_infra_yml}")" \
        '$config * { prefix: ($name + "/terraform.tfstate") }' > "${_tf_backend_json}"
      ;;
    oci)
      jq -n \
        --arg name "${_name}" \
        --arg par "$(yq -r '.backend.pre_authenticated_request' < "${_infra_yml}")" \
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
   --argjson provider "$(yq -r '{provider_config: .provider}' < "${_infra_yml}")" \
   --argjson configs "$(yq -r '.configs' < "${_infra_yml}")" \
    '{ name: $name } * $controller_ip * $provider * $configs' >  "${_tf_variables_json}"

  # prepare _infra_vars_yml
  yq -y -w 1000 '{configs: .spec.infra.configs}' < "${_config_yml}" > "${_infra_vars_yml}"

  # prepare _platform_vars_yml
  yq -y -w 1000 '.spec.platform' < "${_config_yml}" > "${_platform_vars_yml}"

  # prepare _app_vars_yml
  yq -y -w 1000 '.spec.app' < "${_config_yml}" > "${_app_vars_yml}"

  # install ansible requirements
  if [[ -f ansible-requirements.yml ]]; then
    ansible-galaxy install -r ansible-requirements.yml
  fi

  cp -r iac-ref "${tmp_dir}/iac"
  cp -r modules "${tmp_dir}/modules"
  cp "${_tf_backend_json}" "${tmp_dir}/iac/tf-backend.json"
  cp "${_tf_variables_json}" "${tmp_dir}/iac/tf-variables.json"
  cp "${_infra_vars_yml}" "${tmp_dir}/infra-vars.yml"
  cp "${_platform_vars_yml}" "${tmp_dir}/platform-vars.yml"
  cp "${_app_vars_yml}" "${tmp_dir}/app-vars.yml"
}

function install() {
  local _stage
  if contains_element "infra" "${stages[@]}"; then
    apply_tf_shape
  fi
  if extract_inventory && check_inventory; then
    for _stage in "infra" "platform" "app"; do
      if contains_element "${_stage}" "${stages[@]}"; then
        install_plays "${_stage}"
        exit_if_not_ok "${?}"
      fi
    done
  else
    exit 1
  fi
}

function uninstall() {
  local _stage
  if extract_inventory && check_inventory; then
    for _stage in "app" "platform" "infra"; do
      if contains_element "${_stage}" "${stages[@]}"; then
        uninstall_plays "${_stage}"
      fi
    done
  fi
  if contains_element "infra" "${stages[@]}"; then
    if [[ "${csp}" == "bm" ]]; then
      debug_out "Ignoring destroy for bare-metal shape"
    else
      destroy_tf_shape
    fi
  fi
}

function force_destroy() {
  destroy_tf_shape
}

function output() {
  switch_to_script_dir
  debug_out "Initializing tf"
  open_debug_banner
  $(tf_binary) -chdir="${tmp_dir}/iac" init -reconfigure -backend-config=tf-backend.json \
    >&$output_debug 2>&1
  close_debug_banner
  blank_info_line
  debug_out "Publishing tf output"
  open_info_banner
  $(tf_binary) -chdir="${tmp_dir}/iac" output -json | yq -y -w 1000 '.info.value // {} | del(..|nulls)' \
    >&$output_info 2>&1
  close_info_banner
}

function apply_tf_shape() {
  info_out "Applying tf shape"
  abort_option
  switch_to_script_dir
  debug_out "Initializing tf"
  open_debug_banner
  $(tf_binary) -chdir="${tmp_dir}/iac" init -reconfigure -backend-config=tf-backend.json \
    >&$output_debug 2>&1
  close_debug_banner
  debug_out "Planning tf"
  open_info_banner
  $(tf_binary) -chdir="${tmp_dir}/iac" plan -compact-warnings -out=tf-plan -var-file=tf-variables.json -detailed-exitcode \
    >&$output_info 2>&1
  _exit_code=$?
  close_info_banner
  if [[ "${_exit_code}" == "1" ]]; then
    info_out "Failed to determine IaC changes"
    exit 1
  fi
  if [[ "${dry_run}" == "FALSE" ]] && [[ "${_exit_code}" == "2" ]] && [[ -f "${tmp_dir}/iac/tf-plan" ]]; then
    debug_out "Applying tf plan"
    open_info_banner
    $(tf_binary) -chdir="${tmp_dir}/iac" apply tf-plan \
      >&$output_info 2>&1
    _exit_code=$?
    close_info_banner
    if [[ "${_exit_code}" != "0" ]]; then
      exit 1
    fi
  fi
}

function destroy_tf_shape() {
  echo "Destroying tf shape"
  abort_option
  switch_to_script_dir
  debug_out "Initializing tf"
  open_debug_banner
  $(tf_binary) -chdir="${tmp_dir}/iac" init -reconfigure -backend-config=tf-backend.json \
    >&$output_debug 2>&1
  close_debug_banner
  debug_out "Planning tf"
  open_info_banner
  $(tf_binary) -chdir="${tmp_dir}/iac" plan -compact-warnings -out=tf-plan -var-file=tf-variables.json -destroy -detailed-exitcode \
    >&$output_info 2>&1
  _exit_code=$?
  close_info_banner
  if [[ "${_exit_code}" == "1" ]]; then
    info_out "Failed to determine IaC changes"
    exit 1
  fi
  if [[ "${dry_run}" == "FALSE" ]] && [[ "${_exit_code}" == "2" ]] && [[ -f "${tmp_dir}/iac/tf-plan" ]]; then
    debug_out "Applying tf plan"
    open_info_banner
    $(tf_binary) -chdir="${tmp_dir}/iac" apply tf-plan \
      >&$output_info 2>&1
    close_info_banner
  fi
}

function extract_inventory() {
  local _exit_code
  info_out "Extracting inventory"
  switch_to_script_dir
  debug_out "Initializing tf"
  open_debug_banner
  $(tf_binary) -chdir="${tmp_dir}/iac" init -reconfigure -backend-config=tf-backend.json \
    >&$output_debug 2>&1
  close_debug_banner
  debug_out "Planning tf"
  open_debug_banner
  $(tf_binary) -chdir="${tmp_dir}/iac" plan -compact-warnings -out=tf-plan -var-file=tf-variables.json -detailed-exitcode \
    >&$output_debug 2>&1
  _exit_code=$?
  close_debug_banner
  if [[ "${_exit_code}" != "0" ]]; then
    info_out "Cannot extract inventory when there are IaC changes"
    return 1
  else
    debug_out "Capturing tf output"
    $(tf_binary) -chdir="${tmp_dir}/iac" output -json | \
      jq -r '.hosts.value' > "${tmp_dir}/inventory.yml"
    $(tf_binary) -chdir="${tmp_dir}/iac" output -json | \
      yq -y -w 1000 '.playbook_configs.value // {} | {iac: .}' > "${tmp_dir}/iac-vars.yml"
    return 0
  fi
}

function check_inventory() {
  local _retry_counter
  info_out "Checking inventory"
  switch_to_script_dir
  _retry_counter=0
  while ! ansible-playbook \
      -i "${tmp_dir}/inventory.yml" \
      playbooks/check-inventory.yml \
      >&$output_debug 2>&1; do
    if [[ "${_retry_counter}" -ge 15 ]]; then
      info_out "Exhausted attempts waiting for inventory to be ready"
      return 1
    else
      ((_retry_counter++))
      info_out "Waiting for inventory to be ready"
      sleep 20
    fi
  done
  return 0
}

function install_plays() {
  local _stage _task
  _stage="${1}"
  info_out "Installing ${_stage} plays"
  abort_option
  switch_to_script_dir
  for _task in $(yq -r ".tasks | map(.name)[]" < "${_stage}-tasks.yml"); do
    if ! run_play "${_stage}" "${_task}" "present"; then
      info_out "Failed to apply task: <${_stage} / ${_task}>"
      blank_info_line
      return 1
    fi
  done
}

function uninstall_plays() {
  local _stage _task
  _stage="${1}"
  info_out "Uninstalling ${_stage} plays"
  abort_option
  switch_to_script_dir
  for _task in $(yq -r ".tasks | reverse | map(.name)[]" < "${_stage}-tasks.yml"); do
    if ! run_play "${_stage}" "${_task}" "absent"; then
      info_out "Failed to revert task: <${_stage} / ${_task}>"
      blank_info_line
    fi
  done
}

function run_play() {
  local _stage _task _state _tmp_task_dir _task_spec_file _play _when_dry_run _task_vars_file
  local _expression_args _condition_expression _condition_file
  local _task_config_args _task_config_file _config_file_counter _task_config_source _task_config_destination
  local _for_each_expression _for_each_file _each_vars_file _expression_args_for_each
  local _task_targets _target_file _target
  _stage="${1}"
  _task="${2}"
  _state="${3}"
  _tmp_task_dir="${tmp_dir}/${_stage}-tasks/${_task}"
  mkdir -p "${_tmp_task_dir}"
  _task_spec_file="${_tmp_task_dir}/spec.yml"
  yq -y -w 1000 --arg task "${_task}" '.tasks | map(select(.name == $task))[0]' < "${_stage}-tasks.yml" > "${_task_spec_file}"
  _play="$(yq -r '.play' < "${_task_spec_file}")"
  _when_dry_run="$(yq -r '.when_dry_run // "dry-run"' < "${_task_spec_file}")"
  _task_vars_file="${_tmp_task_dir}/vars.yml"
  yq -y -w 1000 '.vars // {} | {task_vars: .}' < "${_task_spec_file}" > "${_task_vars_file}"
  if [[ "${_state}" == "present" ]]; then
    info_out "Applying task: <${_stage} / ${_task}>"
  fi
  if [[ "${_state}" == "absent" ]]; then
    info_out "Reverting task: <${_stage} / ${_task}>"
  fi
  blank_info_line
  _expression_args=()
  _expression_args+=("-e")
  _expression_args+=("@${_task_vars_file}")
  _expression_args+=("-e")
  _expression_args+=("@${tmp_dir}/${_stage}-vars.yml")
  _expression_args+=("-e")
  _expression_args+=("@${tmp_dir}/iac-vars.yml")
  _expression_args+=("-e")
  _expression_args+=("dist_dir=${script_dir}")
  _expression_args+=("-e")
  _expression_args+=("state=${_state}")
  _expression_args+=("-e")
  _expression_args+=("tmp_dir=${tmp_dir}")
  _expression_args+=("-e")
  _expression_args+=("tmp_task_dir=${_tmp_task_dir}")
  _expression_args+=("-e")
  _expression_args+=("dry_run_mode=${dry_run,,}")
  _condition_expression="$(yq -r '.condition // ""' < "${_task_spec_file}")"
  _condition_file="${_tmp_task_dir}/condition.txt"
  if [[ -n "${_condition_expression}" ]]; then
    if ! output_jinja2_expression "${_condition_expression}" "${_condition_file}" "txt" "${_expression_args[@]}"; then
      return 1
    fi
    if [[ "$(tr '[:upper:]' '[:lower:]' < "${_condition_file}")" != "true" ]]; then
      info_out "Skipping task: <${_stage} / ${_task}> since condition: ${_condition_expression} did not evaluate to true"
      blank_info_line
      return 0
    fi
  fi
  _task_config_args=()
  _task_config_file="${_tmp_task_dir}/config.yml"
  yq -r '.config // {} | {task_config: .}' < "${_task_spec_file}" > "${_task_config_file}"
  _task_config_args+=("-e")
  _task_config_args+=("@${_task_config_file}")
  mkdir -p "${_tmp_task_dir}/config-files"
  _config_file_counter=0
  while read -r _config_file; do
    if [[ -n "${_config_file}" ]]; then
      ((_config_file_counter++))
      _task_config_source="${script_dir}/config-files/${_config_file}"
      _task_config_destination="${_tmp_task_dir}/config-files/config-${_config_file_counter}.yml"
      if ! ansible-playbook \
          -c local \
          -i localhost, \
          -e config_source="${_task_config_source}" \
          -e config_destination="${_task_config_destination}" \
          "${_expression_args[@]}" \
          playbooks/copy-task-config.yml \
          >&$output_debug 2>&1; then
        info_out "Could not copy config file: ${_config_file}"
        blank_info_line
        return 1
      fi
      _task_config_args+=("-e")
      _task_config_args+=("@${_task_config_destination}")
    fi
  done <<< "$(yq -r '.config_files // [] | .[]' < "${_task_spec_file}")"
  _for_each_expression="$(yq -r '.for_each // ""' < "${_task_spec_file}")"
  _for_each_file="${_tmp_task_dir}/each.yml"
  if [[ -n "${_for_each_expression}" ]]; then
    if ! output_jinja2_expression "${_for_each_expression}" "${_for_each_file}" "yaml" "${_expression_args[@]}"; then
      return 1
    fi
  else
    yq -ny '{default: {}}' > "${_for_each_file}"
  fi
  for _each_key in $(yq -r 'keys | .[]' < "${_for_each_file}"); do
    _each_vars_file="${_tmp_task_dir}/each-vars.yml"
    yq -y -w 1000 --arg key "${_each_key}" '{task_each_vars: {key: $key, value: .[$key]}}' < "${_for_each_file}" > "${_each_vars_file}"
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
    done <<< "$(yq -r '.targets // [] | .[]' < "${_task_spec_file}")"
    if [[ "${#_task_targets[*]}" -eq 0 ]]; then
      _task_targets+=("all")
    fi
    for _task_target in "${_task_targets[@]}"; do
      if [[ "${dry_run}" == "TRUE" ]] && [[ "${_when_dry_run}" == "dry-run" ]]; then
        ansible-playbook \
          --check \
          -i "${tmp_dir}/inventory.yml" \
          -l "localhost:${_task_target}" \
          "${_task_config_args[@]}" \
          "${_expression_args_for_each[@]}" \
          "playbooks/${_play}.yml" \
          >&$output_info 2>&1
      elif [[ "${dry_run}" != "TRUE" ]] || [[ "${_when_dry_run}" == "run" ]]; then
        if ! ansible-playbook \
            -i "${tmp_dir}/inventory.yml" \
            -l "localhost:${_task_target}" \
            "${_task_config_args[@]}" \
            "${_expression_args_for_each[@]}" \
            "playbooks/${_play}.yml" \
            >&$output_info 2>&1; then
          return 1
        fi
      else
        info_out "Skipping task: <${_stage} / ${_task}> since dry-run: ${dry_run,,} and task is marked: ${_when_dry_run,,} when dry-run is true"
        blank_info_line
      fi
    done
  done
}

function output_jinja2_expression() {
  local _expression _output_file _output_format
  _expression="${1}"
  _output_file="${2}"
  _output_format="${3}"
  if ! ansible-playbook \
      -c local \
      -i localhost, \
      -e expression="${_expression}" \
      -e output_file="${_output_file}" \
      -e output_format="${_output_format}" \
      "${@:4}" \
      playbooks/output-jinja2-expression-to-file.yml; then
    info_out "Could not evaluate expression: ${_expression}"
    return 1
  fi
}

function process_user_config() {
  local _input_file _output_file
  _input_file="${1}"
  _output_file="${2}"
  if ! ansible-playbook \
      -c local \
      -i localhost, \
      -e input_file="${_input_file}" \
      -e output_file="${_output_file}" \
      playbooks/process-user-config.yml \
      >&$output_debug 2>&1; then
    info_out "Could not process config file: ${config_file}"
    exit 1
  fi
}

function register_cleanup_command() {
  cleanup_commands=("${1}" "${cleanup_commands[@]}")
}

function cleanup_tmp_dir() {
  switch_to_script_dir
  rm -rf "${tmp_dir}"
}

function publish_log_file_name() {
  blank_info_line
  open_info_banner
  info_out "Logs for the execution are available at: ${log_file_path}"
  close_info_banner
}

function cleanup() {
  for cleanup_command in "${cleanup_commands[@]}"
  do
    "${cleanup_command}"
  done
}

function abort() {
  info_out "Aborting as SIGTERM/SIGINT received"
  trap - SIGINT SIGTERM # clear the trap
  kill -- -$$ # Sends SIGTERM to child/sub processes
}

trap cleanup EXIT
trap abort SIGINT SIGTERM

initialize_logging "${@}"
execute "${@}"
for command in "${commands[@]}"
do
  "${command}"
  exit_if_not_ok "${?}"
done
