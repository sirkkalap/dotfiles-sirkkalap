#!/bin/sh
# http://jamesreubenknowles.com/disable-spindump-71
sudo launchctl unload -w  /System/Library/LaunchDaemons/com.apple.spindump.plist
