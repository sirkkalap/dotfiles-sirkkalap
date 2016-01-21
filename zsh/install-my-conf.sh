#!/usr/bin/env zsh
(
    cd
    localconf=zshrc.$(hostname).local
    if [ -e proj/dotfiles-sirkkalap/zsh/${localconf} ]; then
        ln -sf proj/dotfiles-sirkkalap/zsh/${localconf} .${localconf}
    fi
)
