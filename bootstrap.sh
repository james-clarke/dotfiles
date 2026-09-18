#!/usr/bin/env bash
#   curl -fsSL https://raw.githubusercontent.com/james-clarke/dotfiles/master/bootstrap.sh | bash
#   DOTFILES_REPO=git@github.com:you/dotfiles bash bootstrap.sh
set -euo pipefail

REPO_URL=${DOTFILES_REPO:-git@github.com:james-clarke/dotfiles}
OS=$(uname -s)
case $OS in Darwin) DEV=${DEV_DIR:-$HOME/Developer} ;; *) DEV=${DEV_DIR:-$HOME/dev} ;; esac
DEST=${DOTFILES_DIR:-$DEV/dotfiles}

step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

step "git + ssh"
missing=""
command -v git >/dev/null || missing="$missing git"
{ [ -n "$(git config --global user.name 2>/dev/null)" ] && [ -n "$(git config --global user.email 2>/dev/null)" ]; } || missing="$missing identity"
out=$(ssh -n -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)
case $out in *"successfully authenticated"*) ;; *) missing="$missing ssh" ;; esac
if [ -n "$missing" ]; then
  cat <<EOM
git is not set up on this machine (missing:$missing). Do that first, then re-run:
  1. git                Debian: sudo apt install git      macOS: xcode-select --install
  2. identity           git config --global user.name "Your Name"
                        git config --global user.email "you@users.noreply.github.com"
  3. SSH key on GitHub  https://docs.github.com/authentication/connecting-to-github-with-ssh
                        ssh -T git@github.com   # must answer "successfully authenticated"
                        (a passphrase-protected key needs ssh-agent loaded first: ssh-add)
EOM
  exit 1
fi
echo "ok         $(git config --global user.name) <$(git config --global user.email)>, SSH to GitHub works"

step "prerequisites"
case $OS in
  Linux)
    command -v curl >/dev/null || { sudo apt-get update -q; sudo apt-get install -y -q curl; } ;;
  Darwin)
    xcode-select -p >/dev/null 2>&1 || { xcode-select --install; echo "finish the CLT install, then re-run"; exit 1; }
    BREW=/opt/homebrew/bin/brew; [ -x "$BREW" ] || BREW=/usr/local/bin/brew
    [ -x "$BREW" ] || { sudo -v; installer=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh); NONINTERACTIVE=1 /bin/bash -c "$installer"; }
    eval "$("$BREW" shellenv)" ;;
  *) echo "unsupported OS: $OS"; exit 1 ;;
esac

step "clone"
if [ ! -d "$DEST/.git" ]; then
  mkdir -p "$(dirname "$DEST")"
  git clone -q --recurse-submodules "$REPO_URL" "$DEST"
fi
exec "$DEST/bin/dots"
