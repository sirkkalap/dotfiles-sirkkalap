#!/usr/bin/env bash
source ~/bin/install_utils.sh
install_utils::init "$0"



if [[ "${distro}" == Ubuntu* ]]; then
    echo "Sorry, I do not know how to install GeekTools on Ubuntu yet..."
    exit 1
fi

if [[ "${distro}" == darwin ]]; then
    brew install dragscroll
fi
