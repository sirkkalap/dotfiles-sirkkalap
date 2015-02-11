#!/bin/bash
#ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
#brew doctor
brew update

brew install caskroom/cask/brew-cask
	git \
	wget
#brew install --universal --java homebrew/versions/subversion17

brew cask install \
	caffeine \
	dropbox

# Disabled
#	crashplan \

#~ ❯❯❯ brew list
#brew-cask			protobuf
#libevent			reattach-to-user-namespace
#mobile-shell			tmux
#openssl				vim
#panamax				wget
#pkg-config
#atomicparsley

# Python
# http://docs.python-guide.org/en/latest/starting/install/osx/
# brew install python python3
# https://github.com/kennethreitz/python-guide/blob/master/docs/dev/virtualenvs.rst
# pip install virtualenv