#!/usr/bin/env bash
source ~/bin/install_utils.sh
install_utils::init "$0"



PACKAGE=vagrant
CASK=cask

if [[ "${distro}" == Ubuntu* ]]; then
    echo "Sorry, I do not know how to install $PACKAGE on Ubuntu yet..."
    exit 1
fi

if [[ "${distro}" == darwin ]]; then
    brew $CASK install $PACKAGE </dev/null
fi
