#!/usr/bin/env bash
# https://linuxize.com/post/how-to-install-sublime-text-3-on-ubuntu-18-04/
source ~/bin/utils_sirkkalap.sh

distro=$(utils_sirkkalap::distro)

if [[ "${distro}" == Ubuntu* ]]; then
    sudo apt update
    sudo apt install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    sudo add-apt-repository "deb https://download.sublimetext.com/ apt/stable/"
    sudo apt update
    sudo apt install sublime-text
fi

if [[ "${distro}" == darwin ]]; then
    brew cask install sublime-text
fi
