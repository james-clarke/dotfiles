#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
UID_=$(id -u)
step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

step "homebrew"
BREW=/opt/homebrew/bin/brew; [ -x "$BREW" ] || BREW=/usr/local/bin/brew
[ -x "$BREW" ] || { echo "homebrew missing; run bootstrap.sh first"; exit 1; }
eval "$("$BREW" shellenv)"
export HOMEBREW_NO_ANALYTICS=1
brew update -q
brew bundle --file="$REPO/os/Brewfile"
brew upgrade -q
brew autoremove -q
brew cleanup -q --prune=all >/dev/null 2>&1 || true

step "emacs daemon"
LA="$HOME/Library/LaunchAgents/com.dotfiles.emacs.plist"
mkdir -p "$(dirname "$LA")"
cp "$REPO/os/macos/emacs.plist" "$LA"
launchctl print "gui/$UID_/com.dotfiles.emacs" >/dev/null 2>&1 \
  || launchctl bootstrap "gui/$UID_" "$LA" \
  || echo "emacs agent not loaded now (no GUI session?); it loads at next login"

step "keyboard: swap caps lock and left ctrl"
LA="$HOME/Library/LaunchAgents/com.dotfiles.capslock.plist"
mkdir -p "$(dirname "$LA")"
cp "$REPO/os/macos/capslock.plist" "$LA"
launchctl bootout "gui/$UID_/com.dotfiles.capslock" 2>/dev/null || true
launchctl bootstrap "gui/$UID_" "$LA" || echo "capslock agent not loaded now (no GUI session?); it loads at next login"

step "ssh keychain"
SSHCFG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
grep -qs 'UseKeychain' "$SSHCFG" || printf 'Host *\n\tAddKeysToAgent yes\n\tUseKeychain yes\n' >> "$SSHCFG"

step "login shell"
[ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" = /bin/zsh ] || chsh -s /bin/zsh

step "zsh completion dirs"
zsh -c 'autoload -Uz compaudit; compaudit' 2>/dev/null | xargs chmod g-w,o-w 2>/dev/null || true
