#!/bin/sh
BASEDIR=$(cd $(dirname $0); /bin/pwd)
(
    $BASEDIR/isodate && \
    /usr/local/bin/brew update && \
    /usr/local/bin/brew upgrade
) >>$HOME/brew-update.log 2>&1
