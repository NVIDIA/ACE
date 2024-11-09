#!/bin/bash

schema_version="0.0.7"
script_name="${0}"
no_prompt="no"
commands=()

function usage() {
  echo "Usage: ${script_name} (-v|--version)"
  echo "   or: ${script_name} (-h|--help)"
  echo "   or: ${script_name} [options]"
  echo ""
  echo "options:"
  echo "-y, --no-prompt    install all dependencies without prompt"
  echo "-h, --help         provide usage information"
}

function execute() {
  validate_args "${@}"
  process_args "${@}"
}

function validate_args() {
  local _args _all_good _valid_args _options _short_options _sub_commands
  _args=("${@}")
  _all_good=0
  _valid_args=$(getopt -q -o yvh --long no-prompt,version,help -- "${_args[@]}")
  _all_good=$(( _all_good + $? ))
  if [[ _all_good -gt 0 ]]; then
    echo "Invalid usage: ${_args[*]}"
  else
    eval set -- "${_valid_args}"
    _options=()
    _short_options=()
    while true; do
      case "${1}" in
        -y | --no-prompt) _options+=("${1}"); _short_options+=("-y"); shift; ;;
        -h | --help) _options+=("${1}"); _short_options+=("-h"); shift; ;;
        -v | --version) _options+=("${1}"); _short_options+=("-v"); shift; ;;
        --) shift; break ;;
      esac
    done
    IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
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
    fi
  fi
  if [[ _all_good -gt 0 ]]; then
    echo ""
    usage
    exit 1
  fi
}

function process_args() {
  local _args _valid_args _short_options
  _args=("${@}")
  _valid_args=$(getopt -q -o yvh --long no-prompt,version,help -- "${_args[@]}")
  eval set -- "${_valid_args}"
  _short_options=()
  while true; do
    case "${1}" in
      -y | --no-prompt) _short_options+=("-y"); shift; ;;
      -h | --help) _short_options+=("-h"); shift; ;;
      -v | --version) _short_options+=("-v"); shift; ;;
      --) shift; break ;;
    esac
  done
  IFS=" " read -r -a _short_options <<< "$(de_dupe_elements "${_short_options[@]}")"
  if [[ "${#_short_options[@]}" -eq 0 ]]; then
    commands+=('verify_pre_requisites')
  elif contains_element "-h" "${_short_options[@]}"; then
    commands+=('usage')
  elif [[ "${#_short_options[@]}" -eq 1 ]]; then
    case "${_short_options[0]}" in
      -y)
        no_prompt="yes"
        commands+=('verify_pre_requisites')
        ;;
      -v)
        commands+=('print_version')
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
  if is_yes "${no_prompt}"; then
    return 0
  else
    read -rp  "Would you like to ${1}? (y/n): " _confirm
    is_yes "${_confirm}"
    return "${?}"
  fi
}

function verify_pre_requisites() {
  local _install_or_update_requirement _all_good _requirements _requirement
  _install_or_update_requirement="$(os_supports_install_or_update_of_requirements)"
  _all_good=0
  verify_privilege_escalation
  _all_good=$(( _all_good + $? ))
  _requirements=()
  _requirements+=('make')
  _requirements+=('git')
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
  else
    echo "all pre-requisites are met"
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
    make | git | jq | yq | terraform)
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
    make)
      make -v | grep 'GNU Make' | awk '{print $3}' 2> /dev/null || echo ""
      ;;
    git)
      git --version | awk '{print $3}' 2> /dev/null || echo ""
      ;;
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
    make)
      echo '4.3'
      ;;
    git)
      echo '2.34.1'
      ;;
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
    make | git | jq | python3 | python3-venv | python3-setuptools | python3-dev | python3-pip)
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

execute "${@}"
for command in "${commands[@]}"
do
  "${command}"
  exit_if_not_ok "${?}"
done

