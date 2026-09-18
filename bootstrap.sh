#!/usr/bin/env bash
# Fresh Debian 13 + KDE or macOS box -> working dev slate. Idempotent; re-run freely.
# Expects git with your identity set and SSH access to GitHub; stops and says so otherwise.
#   curl -fsSL https://raw.githubusercontent.com/james-clarke/dotfiles/master/bootstrap.sh | bash
# Forks: DOTFILES_REPO=git@github.com:you/dotfiles bash bootstrap.sh
set -euo pipefail

REPO_URL=${DOTFILES_REPO:-git@github.com:james-clarke/dotfiles}
OS=$(uname -s)
case $OS in Darwin) DEV=${DEV_DIR:-$HOME/Developer} ;; *) DEV=${DEV_DIR:-$HOME/dev} ;; esac
DEST=${DOTFILES_DIR:-$DEV/dotfiles}
RESTART_EMACS=""

step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

step "git + ssh"
missing=""
command -v git >/dev/null || missing="$missing git"
{ [ -n "$(git config --global user.name 2>/dev/null)" ] && [ -n "$(git config --global user.email 2>/dev/null)" ]; } || missing="$missing identity"
out=$(ssh -n -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)
case $out in *"successfully authenticated"*) ;; *) missing="$missing ssh" ;; esac
if [ -n "$missing" ]; then
  cat <<EOF
git is not set up on this machine (missing:$missing). Do that first, then re-run:
  1. git                Debian: sudo apt install git      macOS: xcode-select --install
  2. identity           git config --global user.name "Your Name"
                        git config --global user.email "you@users.noreply.github.com"
  3. SSH key on GitHub  https://docs.github.com/authentication/connecting-to-github-with-ssh
                        ssh -T git@github.com   # must answer "successfully authenticated"
                        (a passphrase-protected key needs ssh-agent loaded first: ssh-add)
EOF
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
if [ "$DEV" != "$HOME/dev" ] && [ -f "$HOME/dev/dotfiles/install.sh" ] && [ ! -e "$DEST" ]; then
  rmdir "$DEV" 2>/dev/null || true
  [ -e "$DEV" ] && { echo "both $HOME/dev and $DEV exist; merge them by hand, then re-run"; exit 1; }
  mv "$HOME/dev" "$DEV"
  echo "moved      $HOME/dev -> $DEV  (install.sh re-points every symlink)"
  RESTART_EMACS=1
fi
if [ -f "$DEST/install.sh" ]; then
  [ -z "$(git -C "$DEST" status --porcelain)" ] || { echo "$DEST has local changes; commit or stash them, then re-run"; exit 1; }
  OLD=$(git -C "$DEST" rev-parse HEAD)
  git -C "$DEST" pull -q --ff-only || { echo "$DEST has diverged from origin; reconcile it (git -C $DEST pull --rebase), then re-run"; exit 1; }
  git -C "$DEST" submodule update --init -q
  git -C "$DEST" diff --quiet "$OLD" HEAD -- emacs || RESTART_EMACS=1
  echo "updated    $DEST  $(git -C "$DEST" log --oneline "$OLD..HEAD" | wc -l | tr -d ' ') new commit(s)"
else
  mkdir -p "$(dirname "$DEST")"
  git clone -q --recurse-submodules "$REPO_URL" "$DEST"
fi

step "preflight (existing files and tools)"
"$DEST/preflight.sh"

step "symlinks"
"$DEST/install.sh"

case $OS in
  Linux)  "$DEST/os/linux.sh" ;;
  Darwin) "$DEST/os/macos.sh" ;;
esac

if [ -n "$RESTART_EMACS" ]; then
  step "emacs daemon restart (config changed)"
  case $OS in
    Linux)  systemctl --user restart emacs.service 2>/dev/null || echo "daemon not running; it picks the change up at next start" ;;
    Darwin) launchctl kickstart -k "gui/$(id -u)/com.dotfiles.emacs" 2>/dev/null || brew services restart emacs-plus@30 2>/dev/null \
              || echo "not a daemon this repo started; restart yours (emacs --daemon)" ;;
  esac
fi

step "done — manual tail"
cat <<EOF
  0. open a new terminal (or: exec zsh) for shell changes
  1. log out / in  (login shell, session env, keyboard remap)
  2. claude        # log in, then:
     jq -r '.enabledPlugins | keys[]' $DEST/claude/settings.json | xargs -n1 claude plugin install
  3. $DEST/install.sh check
EOF
[ "$OS" = Linux ] && echo "  4. $DEST/kde/apply.sh   # if bootstrap ran outside a Plasma session"
[ "$OS" = Darwin ] && echo "  4. Rectangle asks for Accessibility access once (System Settings > Privacy & Security); window keys need it"
exit 0
