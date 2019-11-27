#!/usr/bin/env bash

source ~/bin/utils_sirkkalap.sh

distro=$(utils_sirkkalap::distro)

#if [[ "${distro}" == Ubuntu* ]]; then
#fi

if [[ "${distro}" == darwin ]]; then
    brew cask install intellij-idea
fi
