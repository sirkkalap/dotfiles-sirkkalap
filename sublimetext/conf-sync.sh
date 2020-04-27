#!/usr/bin/env bash

source ~/bin/utils_sirkkalap.sh

distro=$(utils_sirkkalap::distro)

function clone_sync_repo_if_not_exists()
{
    local CONF_DIR=$1
    if [[ ! -d "${CONF_DIR}/.git" ]]; then
        rm -rf "${CONF_DIR}"
        git clone git@github.com:sirkkalap/sublime-text-settings-sirkkalap.git "${CONF_DIR}"
    else
        echo "Found ${CONF_DIR}/.git folder. Not touching the configuration folder."
    fi
}

if [[ "${distro}" == Ubuntu* ]]; then
	clone_sync_repo_if_not_exists ${HOME}/.config/sublime-text-3/Packages/User
fi

if [[ "${distro}" == darwin ]]; then
	clone_sync_repo_if_not_exists ${HOME}/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
fi
