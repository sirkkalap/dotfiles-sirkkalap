#!/bin/sh

WORK=${1:-$HOME/proj}

mkdir -p "$WORK"

set -e # Fail fast

require() {
    cmd=$1
    shift
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "I require $cmd but it's not installed.  Installing."; eval "$@"; }
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
    require zsh 'sudo yum -y install ncurses-devel &&\
                 wget -O- http://sourceforge.net/projects/zsh/files/zsh/5.0.2/zsh-5.0.2.tar.bz2/download\
                 | tar jxf - &&\
                 cd zsh-5.0.2 &&\
                 ./configure && \
                 make &&\
                 sudo make install'
fi

if [[ $DISTRO == Ubuntu* ]]; then
    require git 'sudo apt-get -y install git'
    require vim 'sudo apt-get -y install vim'
    require zsh 'sudo apt-get -y install zsh'
    require tmux 'sudo apt-get -y install tmux'
fi

if [[ $DISTRO == darvin ]]; then
    echo "here"
    require brew2 'echo "sorry" && exit 1'
    require git 'brew install git'
    require vim 'brew install vim'
    require zsh 'brew install zsh'
    require lynx 'brew install lynx'
    require tmux 'brew install tmux'
fi

(
    cd "$WORK"
    [ ! -d dotfiles-sirkkalap ] && git clone https://github.com/sirkkalap/dotfiles-sirkkalap.git
    cd dotfiles-sirkkalap
    ./zsh/install-prezto.sh
    ./zsh/install-my-conf.sh
    ./vim/install-spf13.sh
    ./vim/install-my-vim-customizations.sh
    ./tmux/install-my-conf.sh
    # Set zsh as my default shell
    [[ ! $SHELL == *zsh ]] && echo "Add $(which zsh) to /etc/shells and run chsh -s $(which zsh) to set zsh as default"
)
