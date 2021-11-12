#!/bin/sh
#
# System profile & rc file.

export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

#######################################
# Global vars
#   ALPINE                "1" if 'DIST_ID' is "alpine".
#   ALPINE_LIKE:          "1" if 'DIST_ID' is "alpine".
#   ARCHLINUX:            "1" if 'DIST_ID' is "arch".
#   BUSYBOX:              "1" if not "/etc/os-release" and not "/sbin".
#   CENTOS:               "1" if 'DIST_ID' is "centos".
#   DARWIN:               "1" if 'UNAME' is "Darwin".
#   DEBIAN:               "1" if 'DIST_ID' is "debian".
#   DEBIAN_LIKE:          "1" if "DIST_ID_LIKE is "debian".
#   DEBIAN_FRONTEND:      "noninteractive" if 'IS_CONTAINER' and 'DEBIAN_LIKE' are set.
#   DIST_CODENAME:        "Catalina", "Big Sur", "kali-rolling", "focal", etc.
#   DIST_ID:              <alpine|centos|debian|kali|macOS|ubuntu>.
#   DIST_ID_LIKE:         <alpine|debian|rhel fedora>.
#   DIST_VERSION:         macOS <10.15.1|10.16|...>, kali <2021.2|...>, ubuntu <20.04|...>.
#   FEDORA:               "1" if 'DIST_ID' is "fedora".
#   IS_CONTAINER:         "1" if running in docker container.
#   FEDORA_LIKE:          "1" if 'DIST_ID' is "fedora" or "fedora" in "DIST_ID_LIKE".
#   KALI:                 "1" if 'DIST_ID' is "kali".
#   NIXOS:                "1" if 'DIST_ID' is "alpine" and "/etc/nix".
#   PM:                   Package manager (apk, apt, brew, nix or yum) for 'DIST_ID'.
#   PM_INSTALL            Package manager install command with options quiet.
#   RHEL:                 "1" if 'DIST_ID' is "rhel".
#   RHEL_LIKE:            "1" if 'DIST_ID' is "rhel" or "rhel" in "DIST_ID_LIKE".
#   UBUNTU:               "1" if 'DIST_ID' is "ubuntu".
#   UNAME:                "linux" or "darwin".
vars() {
  [ -f /.dockerenv ] && export IS_CONTAINER="1"

  ####################################### OS
  #
  export DIST_CODENAME DIST_ID DIST_ID_LIKE DIST_VERSION PM UNAME
  UNAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
  if [ "${UNAME}" = "darwin" ]; then
    export DARWIN="1"
    DIST_ID="$(sw_vers -ProductName)"
    DIST_VERSION="$(sw_vers -ProductVersion)"
    case "$(echo "${DIST_VERSION}" | awk -F. '{ print $1 $2 }')" in
      1013) DIST_CODENAME="High Sierra" ;;
      1014) DIST_CODENAME="Mojave" ;;
      1015) DIST_CODENAME="Catalina" ;;
      11*) DIST_CODENAME="Big Sur" ;;
      12*) DIST_CODENAME="Monterey" ;;
      *) DIST_CODENAME="Other" ;;
    esac
    eval "$(/usr/libexec/path_helper -s)"
    if CLT="$(xcode-select --print-path 2>/dev/null)"; then
      PATH="${PATH}:${CLT}"
    fi
    PM="brew"
  else
    _file="/etc/os-release"
    if test -f "${_file}"; then
      while IFS="=" read -r _var _value; do
        # shellcheck disable=SC2154
        case "${_var}" in
          ID)
            DIST_ID="${_value}"
            case "${DIST_ID}" in
              alpine)
                export ALPINE="1" ALPINE_LIKE="1" DIST_ID_LIKE="${DIST_ID}" PM="apk"
                [ -r "/etc/nix" ] && export NIXOS="1" PM="nix"
                ;;
              arch) export ARCHLINUX="1" PM="pacman" ;;
              centos) export CENTOS="1" PM="yum" ;;
              debian) export DEBIAN="1" DEBIAN_LIKE="1" DIST_ID_LIKE="${DIST_ID}" ;;
              fedora) export FEDORA="1" FEDORA_LIKE="1" PM="dnf" ;;
              kali) export KALI="1" ;;
              rhel) export RHEL="1" RHEL_LIKE="1" PM="yum";;
              ubuntu) export UBUNTU="1" ;;
              *) export DIST_UNKNOWN="1" ;;
            esac
            ;;
          ID_LIKE)
            DIST_ID_LIKE="${_value}"
            case "${DIST_ID_LIKE}" in
              debian)
                export DEBIAN_LIKE="1" PM="apt"
                [ "${IS_CONTAINER-}" ] && export DEBIAN_FRONTEND="noninteractive"
                ;;
              *fedora*) export FEDORA_LIKE="1" ;;
              *rhel*) export RHEL_LIKE="1" ;;
            esac
            ;;
          VERSION_ID) DIST_VERSION="${_value}" ;;
          VERSION_CODENAME) DIST_CODENAME="${_value}" ;;
        esac
      done < "${_file}"
      unset _var _value
    else
      [ -d "/sbin" ] && export BUSYBOX="1"
      unset DIST_CODENAME DIST_ID DIST_ID_LIKE DIST_VERSION PM
      return 2>/dev/null || exit
    fi
    unset _file
  fi

  ####################################### IS_CONTAINER, PM and PM_INSTALL
  #
  case "${PM}" in
    apk) _install="add -q --no-progress" ;;
    apt) _install="install -y -qq" ;;
    brew) _install="install --quiet" ;;
    dnf) _install="install -y -q" ;;
    nix) _install="nix-env --install -A" ;; # nixos -> nixos.curl, no nixos --> nixpkgs.curl
    pacman) _install="-S --noconfirm" ;;
    yum) _install="install -y -q" ;;
  esac
  export PM_INSTALL="${PM} ${_install}"
  unset _install _nocache
}
vars
unset -f vars

###################################### Globals: IS_BASH
#
if [ -n "${BASH_VERSION}" ]; then
  # IS_BASH: "1" if running in bash.
  export IS_BASH="1"
  (return 0 2>/dev/null) && sourced="1"
  # shellcheck disable=SC3028,SC3054
  rc="${BASH_SOURCE[0]}"
elif [ "${0##*/}" = "sh" ]; then
  sourced="1"
  rc="${0}"
else
  return
fi

for script in "${rc}".d/??-*.sh ; do
  if [ -r "${script}" ] ; then
    . "${script}"
  fi
done
unset rc script sourced