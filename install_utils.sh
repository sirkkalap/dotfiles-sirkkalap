#!/usr/bin/env bash

# Common helper for install.sh scripts

# Include guard
[[ -n "$_LIB_INSTALL_UTILS" ]] && return || readonly _LIB_INSTALL_UTILS=1

function install_utils::init() {
    BASEDIR=$(cd "$(dirname "$1")" && /bin/pwd)
    source ~/bin/utils_sirkkalap.sh
    distro=$(utils_sirkkalap::distro)
}
