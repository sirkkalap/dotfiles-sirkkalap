#!/usr/bin/env bash
source ~/bin/install_utils.sh
install_utils::init "$0"

cd ${BASEDIR}



# - https://rclone.org/downloads/
if [[ ${distro} == Ubuntu* ]]; then
    curl https://downloads.rclone.org/rclone-current-linux-amd64.deb -o rclone-current-linux-amd64.deb
    sudo dpkg -i rclone-current-linux-amd64.deb

    utils_sirkkalap::block "Fixing missing dependencies"
    sudo apt-get update && apt-get install -f
fi

