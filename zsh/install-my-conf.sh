#!/usr/bin/env zsh
BASEDIR=$(cd "$(dirname "$0")"; pwd)
(
    cd
    localconf="zshrc.$(hostname)"
    if [ -e "$BASEDIR/${localconf}" ]; then
        ln -sf "$BASEDIR/${localconf}" .${localconf}
    fi
)
