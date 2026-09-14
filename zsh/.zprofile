# Login shells. macOS /etc/zprofile runs path_helper after .zshenv and
# reorders PATH, so user-first order is re-asserted here.
if [[ $OSTYPE == darwin* ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then export HOMEBREW_PREFIX=/opt/homebrew
  else export HOMEBREW_PREFIX=/usr/local; fi
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
fi
path=("$HOME/.local/bin" $path)
