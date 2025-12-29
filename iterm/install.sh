#!/usr/bin/env bash
source ~/bin/install_utils.sh
install_utils::init "$0"



if [[ "${distro}" == Ubuntu* ]]; then
    echo "Sorry, I do not know how to install iterm on Ubuntu yet..."
    exit 1
fi

if [[ "${distro}" == darwin ]]; then
    brew install --cask iterm2
fi
