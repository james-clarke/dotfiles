#!/usr/bin/env bash
# macOS packages + Emacs daemon + keyboard. Idempotent. Called by bootstrap.sh.
# Nothing here compiles: casks and mise binaries only, so a macOS release Homebrew no longer bottles for installs as fast as a current one.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
UID_=$(id -u)
step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

step "homebrew"
BREW=/opt/homebrew/bin/brew; [ -x "$BREW" ] || BREW=/usr/local/bin/brew
[ -x "$BREW" ] || { echo "homebrew missing; run bootstrap.sh first"; exit 1; }
eval "$("$BREW" shellenv)"
export HOMEBREW_NO_ANALYTICS=1
KEEP_EMACS=$(sed -n 's|^emacs/install=||p' "$STATE/preflight" 2>/dev/null | tail -1 || true)
case $KEEP_EMACS in
  keep) export HOMEBREW_BUNDLE_CASK_SKIP="emacs-app" ;;
  replace)
    brew services stop emacs-plus@30 2>/dev/null || true
    for f in $(brew list --formula 2>/dev/null | grep -i '^emacs'); do brew uninstall "$f"; done
    for c in $(brew list --cask 2>/dev/null | grep -i '^emacs' | grep -vx emacs-app); do brew uninstall --cask "$c"; done
    if [ -e /Applications/Emacs.app ] && ! brew list --cask 2>/dev/null | grep -qx emacs-app; then
      OLD="$STATE/archive/$(date +%Y%m%d-%H%M%S)/Applications"
      mkdir -p "$OLD" && mv /Applications/Emacs.app "$OLD/" && echo "archived   /Applications/Emacs.app -> $OLD/"
    fi ;;
esac
brew bundle --file="$REPO/os/Brewfile"

step "mise (prebuilt binary; the Homebrew formula compiles Rust on any macOS without bottles)"
[ -x "$HOME/.local/bin/mise" ] || curl -fsSL https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh
dupes=$(brew list --formula 2>/dev/null | grep -xE 'mise|jq|fzf|eza|zoxide|ripgrep|fd|bat|git-delta|direnv|shellcheck|shfmt|ruff|uv|node' | tr '\n' ' ' || true)
# shellcheck disable=SC2086
[ -z "$dupes" ] || { echo "removing Homebrew copies mise now provides: $dupes"; brew uninstall -q --ignore-dependencies $dupes; }
brew autoremove -q
brew cleanup -q --prune=all >/dev/null 2>&1 || true

step "emacs daemon"
if [ "$KEEP_EMACS" = keep ]; then
  echo "kept your Emacs per preflight; its daemon stays yours (brew services, or emacs --daemon)"
else
  LA="$HOME/Library/LaunchAgents/com.dotfiles.emacs.plist"
  mkdir -p "$(dirname "$LA")"
  cp "$REPO/os/macos/emacs.plist" "$LA"
  launchctl print "gui/$UID_/com.dotfiles.emacs" >/dev/null 2>&1 \
    || launchctl bootstrap "gui/$UID_" "$LA" \
    || echo "emacs agent not loaded now (no GUI session?); it loads at next login"
fi

step "keyboard: swap caps lock and left ctrl"
LA="$HOME/Library/LaunchAgents/com.dotfiles.capslock.plist"
mkdir -p "$(dirname "$LA")"
cp "$REPO/os/macos/capslock.plist" "$LA"
launchctl bootout "gui/$UID_/com.dotfiles.capslock" 2>/dev/null || true
launchctl bootstrap "gui/$UID_" "$LA" || echo "capslock agent not loaded now (no GUI session?); it loads at next login"

step "defaults"
"$REPO/os/macos/defaults.sh"
pgrep -xq Rectangle || open -ga Rectangle || true

step "ssh keychain"
SSHCFG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
grep -qs 'UseKeychain' "$SSHCFG" || printf 'Host *\n\tAddKeysToAgent yes\n\tUseKeychain yes\n' >> "$SSHCFG"

step "login shell"
[ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" = /bin/zsh ] || chsh -s /bin/zsh

step "zsh completion dirs"
zsh -c 'autoload -Uz compaudit; compaudit' 2>/dev/null | xargs chmod g-w,o-w 2>/dev/null || true
