#!/bin/bash
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#brew doctor
# curl -sSL https://raw.githubusercontent.com/sirkkalap/dotfiles-sirkkalap/master/brew/karnak-brew-all.sh | bash -
brew update

# Some dependencies
brew install \
  Caskroom/cask/java \
  xquartz

brew install \
  ansible \
  autoconf \
  autojump \
  automake \
  boot2docker \
  colordiff \
  coreutils \
  diff-pdf \
  docker \
  exiftool \
  fontconfig \
  freetype \
  git \
  gobject-introspection \
  jpeg \
  leiningen \
  libevent \
  libpng \
  libtiff \
  libtool \
  libxml2 \
  libxslt \
  libyaml \
  little-cms2 \
  makedepend \
  maven \
  mercurial \
  mobile-shell \
  mongodb \
  neon \
  nvm \
  pixman \
  pkg-config \
  poppler \
  protobuf \
  python \
  python3 \
  readline \
  reattach-to-user-namespace \
  scons \
  sqlite \
  ssh-copy-id \
  homebrew/versions/subversion17 \
  tcptraceroute \
  tmux \
  tree \
  unrar \
  watch \
  wget \
  wxmac \
  xz \
  zsh

#brew install --universal --java homebrew/versions/subversion17

brew install \
	dropbox \
	etrecheck \
	github-desktop \
	hipchat \
	iterm2 \
	sublime-text \
	vagrant \
	virtualbox \
	wireshark

# Python
# http://docs.python-guide.org/en/latest/starting/install/osx/
# brew install python python3
# https://github.com/kennethreitz/python-guide/blob/master/docs/dev/virtualenvs.rst
# pip install virtualenv
