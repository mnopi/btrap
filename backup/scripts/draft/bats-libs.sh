#!/usr/bin/env bash
#
# Installs and sources bats libraries.

function die-bats-libs() {
  local rc="${1}"
  unset cache func dest repo script
  unset -f die-bats-libs
  exit "${rc}"
}

script="$(basename "${BASH_SOURCE[0]} .sh")"

if (return 0 2>/dev/null); then
  while ((${#})); do
    case "${1}" in
      -h|--help)
        $( which man ) -p cat "${script}" 2>/dev/null
        die-bats-libs
        ;;
      *)
        echo "${script}: ${1}: invalid option"
        die-bats-libs 1
        ;;
    esac
    shift
  done

  cache="${HOME}/.cache"
  mkdir -p "${cache}"
  for repo in bats-assert bats-file bats-support; do
    dest="${cache}/${repo}"
    if test -d "${dest}"; then
      git -C "${dest}" pull --quiet --force 1>/dev/null || die-bats-libs 1
    else
      git clone --quiet "https://github.com/bats-core/${repo}.git" "${dest}" 1>/dev/null || die-bats-libs 1
    fi
    source "${dest}/load.bash"
  done
  for func in assert_equal assert_file_exist batslib_err; do
    declare -pF "${func}" 1>/dev/null || die-bats-libs 1
  done
  return
else
  echo "${script}: must be sourced"
fi
