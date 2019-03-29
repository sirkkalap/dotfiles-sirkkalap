#!/usr/bin/env bash

# https://github.com/docker/docker-credential-helpers
BASEDIR=$(cd $(dirname $0); /bin/pwd)

source ~/bin/utils_sirkkalap.sh

go get github.com/docker/docker-credential-helpers
cd ${GOPATH}/src/github.com/docker/docker-credential-helpers

distro=$(utils_sirkkalap::distro)

if [[ ${distro} == centos* ]]; then
    service=secretservice
    binary=
fi

if [[ ${distro} == Ubuntu* ]]; then
    service=secretservice
    binary=
fi

if [[ ${distro} == darwin ]]; then
    service=osxkeychain
    binary=docker-credential-osxkeychain
fi

make ${service}


utils_sirkkalap::block "Copying binary $binary to ~/go/bin. Add it to your path."

cp -f bin/${binary} ~/go/bin/

utils_sirkkalap::block "Set the credsStore option in your .docker/config.json file"

echo "See: https://github.com/docker/docker-credential-helpers/"
