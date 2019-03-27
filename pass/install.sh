#!/usr/bin/env bash

sudo apt-get install pass

cat << EOF
zx2c4@laptop ~ $ pass init "ZX2C4 Password Storage Key"
mkdir: created directory ‘/home/zx2c4/.password-store’
Password store initialized for ZX2C4 Password Storage Key.
EOF

cat << EOF
zx2c4@laptop ~ $ pass git init
Initialized empty Git repository in /home/zx2c4/.password-store/.git/
zx2c4@laptop ~ $ pass git remote add origin kexec.com:pass-store
EOF

