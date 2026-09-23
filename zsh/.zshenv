export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

typeset -U path
if [[ $OSTYPE == darwin* ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then export HOMEBREW_PREFIX=/opt/homebrew
  else export HOMEBREW_PREFIX=/usr/local; fi
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
fi
path=("$HOME/.local/bin" $path)

[[ $OSTYPE == darwin* ]] && export DEV_DIR="${DEV_DIR:-$HOME/Developer}" || export DEV_DIR="${DEV_DIR:-$HOME/dev}"

export EDITOR=lite-xl VISUAL=lite-xl
export PAGER=less LESSHISTFILE="$XDG_STATE_HOME/less/history"
export npm_config_prefix="$HOME/.local" npm_config_cache="$XDG_CACHE_HOME/npm" npm_config_userconfig="$XDG_CONFIG_HOME/npm/npmrc"
export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
export HOMEBREW_NO_ANALYTICS=1

[[ -f $HOME/.cargo/env ]] && . "$HOME/.cargo/env"
