#!/bin/bash
#ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
#brew doctor

brew install caskroom/cask/brew-cask
brew install \
	autojump \
	git \
	mobile-shell \
	python \
	python3 \
	reattach-to-user-namespace \
	tmux \
	wget \
	zsh 
#brew install --universal --java homebrew/versions/subversion17

brew cask install \
	crashplan \
	dropbox \
	github \
	google-chrome \
	hipchat \
	intellij-idea-ce \
	iterm2 \
	caskroom/versions/java7 \
	sizeup \
	sublime-text \
	superduper \
	virtualbox

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