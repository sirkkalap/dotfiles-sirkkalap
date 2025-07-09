#!/bin/bash
# curl -sSL https://raw.githubusercontent.com/sirkkalap/dotfiles-sirkkalap/master/brew/revontuli-brew-all.sh | bash -
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# brew doctor
brew update

brew install caskroom/cask/brew-cask
brew install \
	autojump \
	git \
	mobile-shell \
	python \
	python3 \
	reattach-to-user-namespace \
	screenresolution \
	tmux \
    vim --with-lua \
	wget \
	zsh
#brew install --universal --java homebrew/versions/subversion17

brew install \
	bettertouchtool \
	cyberduck \
	dropbox \
	github \
	google-chrome \
	hipchat \
	iterm2 \
	itsycal \
	launchcontrol \
	caskroom/versions/java7 \
	sizeup \
	sublime-text \
	vagrant \
    virtualbox

# Disabled
#	crashplan \
#	superduper \

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
