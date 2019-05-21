#!/usr/local/bin/env bash

find ~/Library/Containers/ -type d -name OfficeFileCache -exec rm -r {} +
