#!/usr/bin/env bash

# https://github.com/docker/docker-credential-helpers
BASEDIR=$(cd $(dirname $0); /bin/pwd)

source ~/bin/utils_sirkkalap.sh

go get github.com/docker/docker-credential-helpers
cd docker-credentials-helpers

distro=$(utils_sirkkalap::distro)

if [[ ${distro} == centos* ]]; then
    service=secretservice
fi

if [[ ${distro} == Ubuntu* ]]; then
    service=secretservice
fi

if [[ ${distro} == darwin ]]; then
    service=osxkeychain
fi

make ${service}

