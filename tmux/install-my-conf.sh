#!/bin/sh
BASEDIR=$(cd "$(dirname "$0")"; pwd)
(
  for c in $BASEDIR/*.conf; do
    echo ln -s $c ${HOME}/.${c##*/}
  done
)
