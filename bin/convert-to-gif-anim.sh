#!/bin/sh
# Source: http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
# Dependencies: ffmpeg
#  - To install ffmpeg on macOS + Homebrew: 
# brew install ffmpeg --with-fdk-aac --with-ffplay --with-freetype --with-libass \
# --with-libquvi --with-libvorbis --with-libvpx --with-opus --with-x265

palette="/tmp/palette.png"

filters="fps=15,scale=640:-1:flags=lanczos"

ffmpeg -v warning -i $1 -vf "$filters,palettegen" -y $palette
ffmpeg -v warning -i $1 -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse" -y $2
