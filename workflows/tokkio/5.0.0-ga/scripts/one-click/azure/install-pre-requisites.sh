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
script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
start_time="$(date)"
start_epoch="$(date +%s)"
log_file_path="${script_dir}/logs/$(basename "${script_name}" | sed -e 's/\./-/g' -e 's/_/-/g')-${start_epoch}.log"
tf_binary_name='tofu'
no_prompt="no"
commands=()
cleanup_commands=()
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
  info_out "   or: ${script_name} [options]"
  blank_info_line
  info_out "options:"
  info_out "-t, --tf-binary      the IaC binary to use, can be tofu or terraform, defaults to tofu"
  info_out "-y, --no-prompt    install all dependencies without prompt"
  info_out "-h, --help         provide usage information"
  info_out "-x, --debug        output additional information in order to debug issues"
  close_info_banner
}

function execute() {
  validate_args "${@}"
  process_args "${@}"
}

function validate_args() {
  local _args _all_good _valid_args _options _short_options _tf_binaries _sub_commands _valid_tf_binaries
  _args=("${@}")
  _all_good=0
  _valid_args=$(getopt -q -o t:yvhx --long tf-binary:,no-prompt,version,help,debug -- "${_args[@]}")
  _all_good=$(( _all_good + $? ))
  if [[ _all_good -gt 0 ]]; then
    info_out "Invalid usage: ${_args[*]}"
  else
    eval set -- "${_valid_args}"
    _options=()
    _short_options=()
    _tf_binaries=()
    while true; do
      case "${1}" in
        -t | --tf-binary) _options+=("${1}"); _short_options+=("-t"); shift; _options+=("${1}"); _tf_binaries+=("${1}"); shift; ;;
        -y | --no-prompt) _options+=("${1}"); _short_options+=("-y"); shift; ;;
        -h | --help) _options+=("${1}"); _short_options+=("-h"); shift; ;;
        -v | --version) _options+=("${1}"); _short_options+=("-v"); shift; ;;
        -x | --debug) _options+=("${1}"); _short_options+=("-x"); shift; ;;
        --) shift; break ;;
      esac
    done
    IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
    IFS=" " read -r -a _tf_binaries <<< "$(de_dupe_elements "${_tf_binaries[@]}")"
    _sub_commands=()
    while [[ -n "${1}" ]]; do
      _sub_commands+=("${1}")
      shift
    done
    _valid_tf_binaries=()
    _valid_tf_binaries+=('tofu')
    _valid_tf_binaries+=('terraform')
    if [[ "${#_sub_commands[@]}" -gt 0 ]]; then
      info_out "Invalid usage: ${_args[*]}"
      ((_all_good++))
    else
      if contains_element "-v" "${_short_options[@]}" && [[ "${#_short_options[@]}" -gt 2 ]]; then
        info_out "Invalid usage: ${_args[*]}"
        ((_all_good++))
      elif contains_element "-v" "${_short_options[@]}" && [[ "${#_short_options[@]}" -eq 2 ]] && ! contains_element "-h" "${_short_options[@]}"; then
        info_out "Invalid usage: ${_args[*]}"
        ((_all_good++))
      else
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
  local _args _valid_args _short_options _tf_binaries
  _args=("${@}")
  _valid_args=$(getopt -q -o t:yvhx --long tf-binary:,no-prompt,version,help,debug -- "${_args[@]}")
  eval set -- "${_valid_args}"
  _short_options=()
  _tf_binaries=()
  while true; do
    case "${1}" in
      -t | --tf-binary)  _short_options+=("-t"); shift; _tf_binaries+=("${1}"); shift; ;;
      -y | --no-prompt) _short_options+=("-y"); shift; ;;
      -h | --help) _short_options+=("-h"); shift; ;;
      -v | --version) _short_options+=("-v"); shift; ;;
      -x | --debug) _short_options+=("-x"); shift; ;;
      --) shift; break ;;
    esac
  done
  IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
  IFS=" " read -r -a _tf_binaries <<< "$(de_dupe_elements "${_tf_binaries[@]}")"
  if [[ "${#_short_options[@]}" -eq 0 ]]; then
    commands+=('verify_pre_requisites')
  elif contains_element "-h" "${_short_options[@]}"; then
    commands+=('usage')
  elif contains_element "-v" "${_short_options[@]}"; then
    commands+=('print_version')
  else
    if contains_element "-x" "${_short_options[@]}" ; then
      exec {output_debug}>&$output_debug_on
    fi
    if contains_element "-y" "${_short_options[@]}" ; then
      no_prompt="yes"
    fi
    if [[ "${#_tf_binaries[@]}" -eq 1 ]]; then
      tf_binary_name="${_tf_binaries[0]}"
    fi
    commands+=('verify_pre_requisites')
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
  if is_yes "${no_prompt}"; then
    return 0
  else
    read -r -p "Would you like to ${1}? (y/n): " _confirm 2>&$output_info
    is_yes "${_confirm}"
    return "${?}"
  fi
}

function verify_pre_requisites() {
  local _install_or_update_requirement _all_good _requirements _requirement
  _install_or_update_requirement="$(host_supports_install_or_update_of_requirements)"
  _all_good=0
  verify_privilege_escalation
  _all_good=$(( _all_good + $? ))
  _requirements=()
  _requirements+=('make')
  _requirements+=('git')
  _requirements+=('jq')
  _requirements+=('rsync')
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
  else
    info_out "All pre-requisites are met"
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
    make | git | jq | terraform | tofu)
      hash "${_requirement}"
      return "${?}"
      ;;
    rsync | python3 | python3-venv | python3-pip)
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
    make)
      make -v | grep 'GNU Make' | awk '{print $3}' || echo ""
      ;;
    git)
      git --version | awk '{print $3}' || echo ""
      ;;
    jq)
      jq --version | cut -d '-' -f 2 || echo ""
      ;;
    rsync)
      rsync --version | awk '{print $3}' | head -n 1 || echo ""
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
    make)
      echo '4.3'
      ;;
    git)
      echo '2.34.1'
      ;;
    jq)
      echo '1.6'
      ;;
    rsync)
      echo '3.2.7'
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
    make)
      echo '4.3-*'
      ;;
    git)
      echo '1:2.34.1-*'
      ;;
    jq)
      echo '1.6-*'
      ;;
    rsync)
      echo '3.2.7-*'
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
    make)
      echo '4.3-*'
      ;;
    git)
      echo '1:2.43.0-*'
      ;;
    jq)
      echo '1.7.1-*'
      ;;
    rsync)
      echo '3.2.7-*'
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
    make | git | jq | rsync | terraform | tofu | python3 | python3-venv | python3-pip)
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
    info_out "Installing ${_requirement}"
    if ! requirement_install_or_update "${_requirement}" "${_requirement_preferred_version}"; then
      info_out "Failed to install ${_requirement}"
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
