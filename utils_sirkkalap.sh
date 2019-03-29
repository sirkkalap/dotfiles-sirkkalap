#!/usr/bin/env bash

###################################################
### Functions
###################################################

# Include guard from: https://coderwall.com/p/it3b-q
[[ -n "$_LIB_UTILS_SIRKKALAP" ]] && return || readonly _LIB_UTILS_SIRKKALAP=1


# Determine OS platform
function utils_sirkkalap::distro() {
    local uname=$(uname | tr "[:upper:]" "[:lower:]")
    # If Linux, try to determine specific distribution
    if [[ "$uname" == "linux" ]]; then
        # If available, use LSB to identify distribution
        if [[ -f /etc/lsb-release || -d /etc/lsb-release.d ]]; then
            export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
        # Otherwise, use release info file
        else
            export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
        fi
    fi
    # For everything else (or if above failed), just use generic identifier
    [[ "$DISTRO" == "" ]] && export DISTRO=${uname}

    echo ${DISTRO}
}


# append_path() and prepend_path() adapted from Fink's init.sh

# "(If the shell supported a real list data structure instead
# of these stupid colon-delimited strings, none of this would be
# necessary. I wonder if there's a Python-based shell out there...)"

# add to end of path
function utils_sirkkalap::append_path()
{
    if eval test -z "\$$1"
    then
        eval "export $1=$2"
    fi

    if ! eval test -z "\"\${$1##*:$2:*}\"" -o -z "\"\${$1%%*:$2}\"" -o -z "\"\${$1##$2:*}\"" -o -z "\"
\${$1##$2}\""
    then
        eval "export $1=\$$1:$2"
    fi
}

# add to front of path
function utils_sirkkalap::prepend_path()
{
    if eval test -z "\$$1"
    then
      eval "export $1=$2"
      return
    fi

    if ! eval test -z "\"\${$1##*:$2:*}\"" -o -z "\"\${$1%%*:$2}\"" -o -z "\"\${$1##$2:*}\"" -o -z "\"
\${$1##$2}\""
    then
      eval "export $1=$2:\$$1"
    fi
}

function utils_sirkkalap::prepend_path_if_exists()
{
    if [ -d "$2" ]
    then
        utils_sirkkalap::prepend_path $1 $2
    fi
}

function funcspappend_path_if_exists()
{
    if [ -d "$2" ]
    then
        utils_sirkkalap::append_path $1 $2
    fi
}

# From http://stackoverflow.com/questions/3231804/in-bash-how-to-add-are-you-sure-y-n-to-any-command-or-alias
# utils_sirkkalap::confirm && hg push ssh://..
# utils_sirkkalap::confirm "Would you really like to do a push?" && hg push ssh://..

function utils_sirkkalap::confirm () {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case $response in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

function utils_sirkkalap::block() {
    text="* $@ *"
    chars=${#text}
    printf '*%.0s' $(seq 1 $chars); echo
    echo "$text"
    printf '*%.0s' $(seq 1 $chars); echo; echo
}

# Print out a block of *'s and the given text inside it
function utils_sirkkalap::block() {
    text="* $@ *"
    chars=${#text}
    printf '*%.0s' $(seq 1 $chars); echo
    echo "$text"
    printf '*%.0s' $(seq 1 $chars); echo; echo
}
