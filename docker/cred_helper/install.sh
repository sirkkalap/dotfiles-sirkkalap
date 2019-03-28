#!/usr/bin/env bash

# https://github.com/docker/docker-credential-helpers
BASEDIR=$(cd $(dirname $0); /bin/pwd)

source ${BASEDIR}/../../utils_sirkkalap.sh

go get github.com/docker/docker-credential-helpers
cd $GOPATH/docker/docker-credentials-helpers
make
