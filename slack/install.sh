#!/usr/bin/env bash
source ~/bin/install_utils.sh
install_utils::init "$0"



#if [[ "${distro}" == Ubuntu* ]]; then
#fi

if [[ "${distro}" == darwin ]]; then
    brew install --cask slack
fi
