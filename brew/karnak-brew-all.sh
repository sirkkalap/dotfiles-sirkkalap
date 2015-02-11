#!/bin/bash
#ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
#brew doctor
brew update

brew install caskroom/cask/brew-cask
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
  subversion17 \
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

brew cask install \
	caskroom/versions/java7 \
	dropbox \
	etrecheck \
	github \
	google-chrome \
	hipchat \
	intellij-idea-ce \
	iterm2 \
	mactex \
	sizeup \
	soundcleod
	sublime-text \
	virtualbox \
	wireshark


# Disabled
#	crashplan \

# Python
# http://docs.python-guide.org/en/latest/starting/install/osx/
# brew install python python3
# https://github.com/kennethreitz/python-guide/blob/master/docs/dev/virtualenvs.rst
# pip install virtualenv
