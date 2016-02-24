#!/bin/sh
# pull and compile tmux
# https://github.com/tmux/tmux/blob/master/README

git clone https://github.com/tmux/tmux.git
cd tmux
sh autogen.sh
./configure && make

echo "run \nsudo install\n here, if you want to install globally"