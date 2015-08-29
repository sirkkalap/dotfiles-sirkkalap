#!/bin/sh
(
cd $HOME/.spf13-vim-3/
git pull
vim +BundleInstall! +BundleClean +q
)

