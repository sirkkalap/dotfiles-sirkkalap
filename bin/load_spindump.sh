#!/bin/sh
# http://jamesreubenknowles.com/disable-spindump-71
sudo launchctl load -w  /System/Library/LaunchDaemons/com.apple.spindump.plist
