#!/bin/sh
(
cd $HOME/to/spf13-vim/
git pull
vim +BundleInstall! +BundleClean +q
)

