#!/bin/bash
#ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
#brew doctor
# curl -sSL https://raw.githubusercontent.com/sirkkalap/dotfiles-sirkkalap/master/brew/karnak-brew-all.sh | bash -
brew update

# Install xquartz, since diff-pdf needs it
brew cask install xquartz

brew install \
  ansible \
  autoconf \
  autojump \
  automake \
  colordiff \
  coreutils \
  diff-pdf \
  docker \
  docker-machine \
  exiftool \
  git \
  leiningen \
  libevent \
  maven \
  mobile-shell \
  mongodb \
  nvm \
  python \
  python3 \
  readline \
  reattach-to-user-namespace \
  ssh-copy-id \
  tcptraceroute \
  tmux \
  tree \
  unrar \
  watch \
  wget \
  zsh

# brew install --universal --java homebrew/versions/subversion17

brew cask install \
  etrecheck \
  github-desktop \
  google-chrome \
  hipchat \
  iterm2 \
  sublime-text \
  vagrant \
  wireshark

# Python
# http://docs.python-guide.org/en/latest/starting/install/osx/
brew install python python3
# https://github.com/kennethreitz/python-guide/blob/master/docs/dev/virtualenvs.rst
pip install virtualenv
