# Sourced by every zsh (login, interactive, scripts). Env only; no output.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

typeset -U path
path=("$HOME/.local/bin" $path)

export EDITOR='emacsclient -t' VISUAL='emacsclient -t' ALTERNATE_EDITOR=''
export PAGER=less LESSHISTFILE="$XDG_STATE_HOME/less/history"
export npm_config_cache="$XDG_CACHE_HOME/npm" npm_config_userconfig="$XDG_CONFIG_HOME/npm/npmrc"
export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
export HOMEBREW_NO_ANALYTICS=1

[[ -f $HOME/.cargo/env ]] && . "$HOME/.cargo/env"
