#!/usr/bin/env zsh
if [ ! -e ${ZDOTDIR:-$HOME}/.zprezto ]; then
  git clone --recursive https://github.com/sirkkalap/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
fi

(
  setopt EXTENDED_GLOB
  for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
    ln -sf "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
  done
)
