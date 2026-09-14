#!/usr/bin/env bash
# macOS packages + Emacs daemon + keyboard. Idempotent. Called by bootstrap.sh.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

step "homebrew"
BREW=/opt/homebrew/bin/brew; [ -x "$BREW" ] || BREW=/usr/local/bin/brew
[ -x "$BREW" ] || { echo "homebrew missing; run bootstrap.sh first"; exit 1; }
eval "$("$BREW" shellenv)"
export HOMEBREW_NO_ANALYTICS=1
KEEP_EMACS=$(sed -n 's|^emacs/install=||p' "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/preflight" 2>/dev/null | tail -1)
[ "$KEEP_EMACS" = keep ] && export HOMEBREW_BUNDLE_BREW_SKIP="emacs-plus@30"
brew bundle --file "$REPO/os/Brewfile"

step "emacs daemon"
if [ "$KEEP_EMACS" = keep ]; then
  echo "kept your Emacs per preflight; run its daemon yourself (emacs --daemon)"
else
  [ -e /Applications/Emacs.app ] || cp -r "$(brew --prefix)/opt/emacs-plus@30/Emacs.app" /Applications/
  brew services list | grep -qE '^emacs-plus@30\s+started' || brew services start d12frosted/emacs-plus/emacs-plus@30
fi

step "keyboard: swap caps lock and left ctrl"
LA="$HOME/Library/LaunchAgents/com.dotfiles.capslock.plist"
mkdir -p "$(dirname "$LA")"
cp "$REPO/os/macos/capslock.plist" "$LA"
launchctl bootout "gui/$(id -u)/com.dotfiles.capslock" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LA"

step "defaults"
"$REPO/os/macos/defaults.sh"

step "ssh keychain"
SSHCFG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
grep -qs 'UseKeychain' "$SSHCFG" || printf 'Host *\n\tAddKeysToAgent yes\n\tUseKeychain yes\n' >> "$SSHCFG"

step "login shell"
[ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" = /bin/zsh ] || chsh -s /bin/zsh

step "zsh completion dirs"
zsh -c 'autoload -Uz compaudit; compaudit' 2>/dev/null | xargs chmod g-w,o-w 2>/dev/null || true
