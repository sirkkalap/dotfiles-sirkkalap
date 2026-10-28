#!/usr/bin/env bash
source ~/bin/install_utils.sh
install_utils::init "$0"




PACKAGE=rectangle

if [[ "${distro}" == Ubuntu* ]]; then
    echo "Sorry, I do not know how to install $PACKAGE on Ubuntu yet..."
    exit 1
fi

if [[ "${distro}" == darwin ]]; then
    brew install --cask $PACKAGE </dev/null
fi
