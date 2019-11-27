#!/usr/bin/env bash

source ~/bin/utils_sirkkalap.sh

distro=$(utils_sirkkalap::distro)

if [[ "${distro}" == Ubuntu* ]]; then
    echo "Sorry, I do not know how to install java on Ubuntu yet..."
    exit 1
fi

if [[ "${distro}" == darwin ]]; then
    brew cask install sublime-text
fi
