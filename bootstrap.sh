#!/usr/bin/env bash
# Fresh Debian 13 + KDE or macOS box -> working dev slate. Idempotent; re-run freely.
#   curl -fsSL https://raw.githubusercontent.com/james-clarke/dotfiles/master/bootstrap.sh | bash
# Forks: DOTFILES_REPO=https://github.com/you/dotfiles bash bootstrap.sh
set -euo pipefail

REPO_URL=${DOTFILES_REPO:-https://github.com/james-clarke/dotfiles}
DEST=${DOTFILES_DIR:-$HOME/dev/dotfiles}
BIN="$HOME/.local/bin"
OS=$(uname -s)

step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

step "prerequisites"
case $OS in
  Linux)
    sudo apt-get update -q
    sudo apt-get install -y -q git gh curl ;;
  Darwin)
    xcode-select -p >/dev/null 2>&1 || { xcode-select --install; echo "finish the CLT install, then re-run"; exit 1; }
    BREW=/opt/homebrew/bin/brew; [ -x "$BREW" ] || BREW=/usr/local/bin/brew
    [ -x "$BREW" ] || { installer=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh); /bin/bash -c "$installer"; }
    eval "$("$BREW" shellenv)"
    brew install -q git gh ;;
  *) echo "unsupported OS: $OS"; exit 1 ;;
esac

step "gh auth"
if ! gh auth status >/dev/null 2>&1; then
  { : </dev/tty; } 2>/dev/null || { echo "not logged in and no terminal. Run: gh auth login -h github.com -p https -w -s admin:public_key  (answer n to git auth)"; exit 1; }
  gh auth login -h github.com -p https -w -s admin:public_key </dev/tty
fi

step "clone"
if [ -f "$DEST/install.sh" ]; then
  git -C "$DEST" pull -q --ff-only
  git -C "$DEST" submodule update --init -q
else
  mkdir -p "$(dirname "$DEST")"
  git -c credential.helper='!gh auth git-credential' clone -q --recurse-submodules "$REPO_URL" "$DEST"
fi

step "preflight (existing files and tools)"
"$DEST/preflight.sh"
decided() { sed -n "s|^$1=||p" "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/preflight" 2>/dev/null | tail -1; }

step "symlinks"
"$DEST/install.sh"

step "git identity + ssh signing (last prompts; the rest runs unattended)"
LOCAL="$HOME/.config/git/config.local"
if [ -z "$(git config -f "$LOCAL" user.email || true)" ]; then
  read -rp "git user.name:  " name  </dev/tty
  read -rp "git user.email (GitHub noreply address keeps commits private): " email </dev/tty
  git config -f "$LOCAL" user.name "$name"
  git config -f "$LOCAL" user.email "$email"
fi
email=$(git config -f "$LOCAL" user.email)
KEY="$HOME/.ssh/id_ed25519"
if [ "$(decided ssh/key)" = skip ]; then
  echo "ssh key skipped per preflight; signing stays off"
else
  [ -f "$KEY" ] || ssh-keygen -t ed25519 -C "$email" -f "$KEY"
  SIGNERS="$HOME/.config/git/allowed_signers"
  line="$email $(cut -d' ' -f1,2 "$KEY.pub")"
  grep -qxF "$line" "$SIGNERS" 2>/dev/null || printf '%s\n' "$line" >> "$SIGNERS"
  gh ssh-key list >/dev/null 2>&1 || gh auth refresh -h github.com -s admin:public_key
  if ! gh ssh-key list | grep -qF "$(cut -d' ' -f2 "$KEY.pub")"; then
    gh ssh-key add "$KEY.pub" --type authentication --title "$(hostname)"
    gh ssh-key add "$KEY.pub" --type signing --title "$(hostname) signing"
  fi
fi

case $OS in
  Linux)  "$DEST/os/linux.sh" ;;
  Darwin) "$DEST/os/macos.sh" ;;
esac

step "mise"
export PATH="$BIN:$PATH"
mise install --yes

step "done — manual tail"
cat <<EOF
  1. log out / in  (login shell, session env, keyboard remap)
  2. claude        # log in, then:
     jq -r '.enabledPlugins | keys[]' $DEST/claude/settings.json | xargs -n1 claude plugin install
  3. $DEST/install.sh check
EOF
[ "$OS" = Linux ] && echo "  4. $DEST/kde/apply.sh   # if bootstrap ran outside a Plasma session"
exit 0
