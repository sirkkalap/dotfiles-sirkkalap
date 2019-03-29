#!/usr/bin/env bash

source ~/bin/utils_sirkkalap.sh

distro=$(utils_sirkkalap::distro)

if [[ ${distro} == darvin ]]; then
    brew install go
fi

if [[ ${DISTRO} == Ubuntu* ]] || [[ ${distro} == centos* ]]; then
    go_version=go1.12.1
    go_checksum=2a3fdabf665496a0db5f41ec6af7a9b15a49fbe71a85a50ca38b1f13a103aeec
    curl -O https://dl.google.com/go/${go_version}linux-amd64.tar.gz
    sha256sum=$(sha256sum ${go_version}.linux-amd64.tar.gz | cut -f1 -d' ')
    if [[ "${sha256sum}" != "${go_checksum}" ]]; then
        echo "Tar file sha256sum mismatch. Corrupted download or tainted source. Exiting."
        exit 127
    fi

    rm -rf ./go
    tar xf go1.10.3.linux-amd64.tar.gz
    rm -f go1.10.3.linux-amd64.tar.gz

    root_group=$(id -g -n root)
    sudo chown -R root:${root_group} ./go
    sudo rm -rf /usr/local/go
    sudo mv go /usr/local

    echo "Installed go to /usr/local/go/*"
fi

# Default project folder and default install folder
mkdir -p ~/go/bin

if [[ -e ~/.paths.d ]]; then
    [[ -e /usr/local/go/bin ]] && echo "/usr/local/go/bin" >~/.paths.d/_usr_local_go.path
    echo "$HOME/go/bin" >~/.paths.d/home_go_bin
else
    echo "Missing ~/.paths.d folder. Set up GO to path manually."
fi

if [[ -e ~/.env.d ]]; then
    echo "export GOPATH=$HOME/go" >~/.env.d/go.sh
else
    echo "Missing ~/.env.d folder. Set up GO env manually."
fi

utils_sirkkalap::block "Evaluate your profile or restart shell to use go"

