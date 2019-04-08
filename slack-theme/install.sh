#!/usr/bin/env bash


# https://github.com/mykeels/slack-theme-cli
curl https://raw.githubusercontent.com/mykeels/slack-theme-cli/master/slack-theme -O
SLACK_THEME_SHELL_PROFILE=~/.zshrc.local bash slack-theme install
. ~/.zshrc.local

# Let's keep paths organized and not append ad infinitum
sed '/export PATH=$PATH:/Users/petrisi/bin/slack-theme/d' ~/.zshrc.local
echo "~/bin/slack-theme" > ~/.paths.d/home_bin_slack-theme

