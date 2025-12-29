#!/usr/bin/env bash
source ~/bin/install_utils.sh
install_utils::init "$0"



if [[ "${distro}" == Ubuntu* ]]; then
    echo "Sorry, I do not know how to install java on Ubuntu yet..."
    exit 1
fi

if [[ "${distro}" == darwin ]]; then
    # AdoptOpenJDK 14 is retired; use the Temurin 14 cask instead.
    brew install --cask temurin@14
fi
