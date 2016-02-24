#!/bin/sh
# pull and compile tmux
# https://github.com/tmux/tmux/blob/master/README

# Dependencies: automake

set -e # Fail fast

(
  wget https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz
  tar zxf libevent-2.0.22-stable.tar.gz
  cd libevent-2.0.22-stable
  ./configure && make
)

(
  git clone https://github.com/tmux/tmux.git
  cd tmux
  sh autogen.sh
  DIR="../libevent-2.0.22-stable"
  ./configure CFLAGS="-I$DIR/include" LDFLAGS="-L$DIR/lib"
  make
)

echo "run \nsudo tmux/install\n, if you want to install globally"
