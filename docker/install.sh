#!/usr/bin/env bash
source ~/bin/install_utils.sh
install_utils::init "$0"



if [[ "${distro}" == Ubuntu* ]]; then
    sudo apt update
    sudo apt install apt-transport-https ca-certificates curl software-properties-common
    curl -fssl https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
    sudo apt update
    sudo apt install docker-ce
    sudo usermod -aG docker ${USER}
fi

if [[ "${distro}" == darwin ]]; then
    brew install docker
    open /Applications/Docker.app
fi
