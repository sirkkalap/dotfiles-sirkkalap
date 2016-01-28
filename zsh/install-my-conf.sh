#!/usr/bin/env zsh
BASEDIR=$(cd "$(dirname "$0")"; pwd)
(
    cd
    localconf="zshrc.$(hostname)"
    if [ -e "$BASEDIR/${localconf}" ]; then
        ln -sf "$BASEDIR/${localconf}" .${localconf}
    fi
    if [ ! -e ~/bin/functions_sirkkalap.sh ]; then
        mkdir -p ~/bin
        ln -sf "$BASEDIR/../functions_sirkkalap.sh" ~/bin/functions_sirkkalap.sh
    fi
)
