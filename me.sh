#!/bin/sh

WORK=${1:-$HOME/proj}

set -e # Fail fast

require() {
    command -v $1 >/dev/null 2>&1 || { echo >&2 "I require $1 but it's not installed.  Installing."; sudo $2; }
}

# Determine OS platform
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && export DISTRO=$UNAME
unset UNAME

if [[ $DISTRO == centos* ]]; then
    require git 'sudo yum -y install git'
    require vim 'sudo yum -y install vim-enhanced'
fi

if [[ $DISTRO == ubuntu* ]]; then
    require git 'sudo apt-get -y install git'
    require vim 'sudo apt-get -y install vim-enhanced'
fi

if [[ $DISTRO == darvin ]]; then
    echo "here"
    require brew2 'echo "sorry" && exit 1'
    require git 'brew install git'
    require vim 'brew install vim'
    require lynx 'brew install lynx'
fi

(
    cd "$WORK"
    git clone https://github.com/sirkkalap/dotfiles-sirkkalap.git
    cd dotfiles-sirkkalap
    ./zsh/install-prezto.sh
    ./zsh/install-my-conf.sh
    ./vim/install-spf13.sh
    ./tmux/install-my-conf.sh
)
