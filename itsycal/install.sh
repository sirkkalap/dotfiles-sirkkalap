#!/usr/bin/env bash

BASEDIR=$(cd $(dirname $0); /bin/pwd)

source ~/bin/utils_sirkkalap.sh

distro=$(utils_sirkkalap::distro)

PACKAGE=itsycal
CASK=

if [[ "${distro}" == Ubuntu* ]]; then
    echo "Sorry, I do not know how to install $PACKAGE on Ubuntu yet..."
    exit 1
fi

if [[ "${distro}" == darwin ]]; then
    brew $CASK install $PACKAGE </dev/null
fi
