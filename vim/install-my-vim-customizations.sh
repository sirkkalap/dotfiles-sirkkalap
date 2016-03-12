#!/bin/sh
BASEDIR=$(cd "$(dirname "$0")"; pwd)
(
    cd
    ln -sf "${BASEDIR}"/vimrc.local .vimrc.local
    ln -sf "${BASEDIR}"/vimrc.bundles.local .vimrc.bundles.local
)
