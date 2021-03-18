#!/usr/bin/env bash

source ~/bin/utils_sirkkalap.sh

distro=$(utils_sirkkalap::distro)

if [[ "${distro}" == Ubuntu* ]]; then
    echo "Sorry, I do not know how to install docker-edge on Ubuntu yet..."
    exit 1
fi

if [[ "${distro}" == darwin ]]; then
    brew install docker-edge
    open /Applications/Docker.app
fi
