#!/usr/bin/env bash

WORK=${1:-$HOME/proj}

BASEDIR=$(cd $(dirname $0); /bin/pwd)

source ${BASEDIR}/utils_sirkkalap.sh

mkdir -p "$WORK"

set -e # Fail fast

require() {
    cmd=$1
    shift
    command -v ${cmd} >/dev/null 2>&1 || { echo >&2 "I require ${cmd} but it's not installed.  Installing."; eval "$@"; }
}

mkdir -p ~/bin
mkdir -p ~/.paths.d
mkdir -p ~/.env.d
echo "~/bin" >~/.paths.d/home_bin
echo "/opt/homebrew/bin" >~/.paths.d/opt_homebrew_bin
echo "/opt/homebrew/opt/libpq/bin" >~/.paths.d/opt_homebrew_opt_libpq_bin
ln -s -f ${WORK}/dotfiles-sirkkalap/utils_sirkkalap.sh ~/bin/
ln -s -f ${WORK}/dotfiles-sirkkalap/install_utils.sh ~/bin/


DISTRO=$(utils_sirkkalap::distro)

if [[ ${DISTRO} == centos* ]]; then
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

if [[ ${DISTRO} == Ubuntu* ]]; then
    require curl 'sudo apt-get -y install curl'
    require git 'sudo apt-get -y install git'
    require vim 'sudo apt-get -y install vim'
    require zsh 'sudo apt-get -y install zsh'
    require tmux 'sudo apt-get -y install tmux'
    require make 'sudo apt-get -y install build-essential'
    require go 'go/install.sh'
    require tree 'sudo apt-get -y install tree'
    require netstat 'sudo apt-get -y install net-tools'
    require apt-file 'sudo apt-get -y install apt-file'
    # https://github.com/visit1985/mdp
    require mdp    '[[ -e /usr/lib/x86_64-linux-gnu/libncursesw.so ]] || sudo apt-get install -y libncursesw5-dev&&\
                    git clone https://github.com/visit1985/mdp.git&&\
                    cd mdp&&\
                    make&&\
                    sudo make install'
fi

if [[ ${DISTRO} == darwin ]]; then
    require brew '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'
    require git 'brew install git'
    require vim 'brew install vim'
    require /opt/homebrew/bin/zsh 'brew install zsh'
    require lynx 'brew install lynx'
    require tmux 'brew install tmux'
    # require reattach-to-user-namespace 'brew install reattach-to-user-namespace'
    require go 'brew install go'
    require tree 'brew install tree'
    require subl "${BASEDIR}/sublimetext/install.sh"
    #require pandoc 'brew install pandoc'
fi


cd "$WORK"
if [[ ! -d dotfiles-sirkkalap ]]; then
    git clone https://github.com/sirkkalap/dotfiles-sirkkalap.git
    cd dotfiles-sirkkalap
else
    cd dotfiles-sirkkalap
    git pull --quiet
fi

# Git lg alias
git config --global alias.lg \
  "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"

./zsh/install-prezto.sh
./zsh/install-my-conf.sh
if [[ ! -d ~/.spf13-vim-3 ]]; then
    ./vim/install-spf13.sh
    ./vim/install-my-vim-customizations.sh
fi
./tmux/install-my-conf.sh
# Set zsh as my default shell
if [[ ! $SHELL == *zsh ]]; then
    echo "Add $(which zsh) to /etc/shells and run chsh -s $(which zsh) to set zsh as default"
fi

(
    cd ~/.env.d
    ln -s -f ~/proj/dotfiles-sirkkalap/dot_env.d/*.sh .

)
