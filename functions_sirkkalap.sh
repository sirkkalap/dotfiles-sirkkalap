#!/bin/sh

###################################################
### Functions
###################################################

# Include guard from: https://coderwall.com/p/it3b-q
[ -n "$_LIB_FUNCTIONS_SIRKKALAP" ] && return || readonly _LIB_FUNCTIONS_SIRKKALAP=1


# append_path() and prepend_path() adapted from Fink's init.sh

# "(If the shell supported a real list data structure instead
# of these stupid colon-delimited strings, none of this would be
# necessary. I wonder if there's a Python-based shell out there...)"

# add to end of path
append_path()
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
prepend_path()
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

prepend_path_if_exists()
{
    if [ -d "$2" ]
    then
        prepend_path $1 $2
    fi
}
append_path_if_exists()
{
    if [ -d "$2" ]
    then
        append_path $1 $2
    fi
}

# From http://stackoverflow.com/questions/3231804/in-bash-how-to-add-are-you-sure-y-n-to-any-command-or-alias
# confirm && hg push ssh://..
# confirm "Would you really like to do a push?" && hg push ssh://..

confirm () {
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

