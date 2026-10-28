#!/usr/bin/env bash
source ~/bin/install_utils.sh
install_utils::init "$0"



if [[ "${distro}" == Ubuntu* ]]; then
    codename=$(lsb_release -cs)
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg software-properties-common
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker ${USER}
fi

if [[ "${distro}" == darwin ]]; then
    brew install --cask docker
    open /Applications/Docker.app
fi
