[[ -n $HOMEBREW_PREFIX ]] && path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
path=("$HOME/.local/bin" $path)
