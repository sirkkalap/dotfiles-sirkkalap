#!/bin/sh
BASEDIR=$(cd "$(dirname "$0")"; pwd)
(
  cd $HOME
  for c in $BASEDIR/*.conf; do
    echo ln -s $c .$c
  done
)
