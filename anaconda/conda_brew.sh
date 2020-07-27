# Deactivates conda before running brew.
# Re-activates conda if it was active upon completion.
# See: https://stackoverflow.com/a/62179041

brew() {

    python_actual=$(which python)
    if [[ $python_actual =~ .*anaconda.* ]] then
        echo "Nope, your Python has Anaconda in the path. Homebrew and Anaconda do not play nicely together."
        return 255
    fi

    local conda_env="$CONDA_DEFAULT_ENV"
    while [ "$CONDA_SHLVL" -gt 0  ]; do
        conda deactivate
    done
    /usr/local/bin/brew $@
    local brew_status=$?
    [ -n "${conda_env:+x}" ] && conda activate "$conda_env"
    return "$brew_status"
}