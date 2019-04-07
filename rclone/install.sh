#!/usr/bin/env bash

BASEDIR=$(cd $(dirname $0); /bin/pwd)
cd ${BASEDIR}

source ~/bin/utils_sirkkalap.sh

distro=$(utils_sirkkalap::distro)

# - https://rclone.org/downloads/
if [[ ${distro} == Ubuntu* ]]; then
    curl https://downloads.rclone.org/rclone-current-linux-amd64.deb -o rclone-current-linux-amd64.deb
    sudo dpkg -i rclone-current-linux-amd64.deb

    utils_sirkkalap::block "Fixing missing dependencies"
    sudo apt-get update && apt-get install -f
fi

