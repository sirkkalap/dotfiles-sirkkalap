# From:
# https://www.reddit.com/r/MacOS/comments/1no872w/psa_macos_26_bug_leads_to_performance_issues_in/?rdt=33740
defaults write -g NSAutoFillHeuristicControllerEnabled -bool false
## Run after every boot:
launchctl setenv CHROME_HEADLESS 1
