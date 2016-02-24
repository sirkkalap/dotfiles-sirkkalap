#!/bin/sh
# pull and compile tmux
# https://github.com/tmux/tmux/blob/master/README

# Dependencies: automake

set -e # Fail fast

(
  curl -sSL https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz
  tar zxf libevent-2.0.22-stable.tar.gz
  cd libevent-2.0.22
  ./configure && make
)

(
  git clone https://github.com/tmux/tmux.git
  cd tmux
  sh autogen.sh
  ./configure && make
)

echo "run \nsudo tmux/install\n, if you want to install globally"
