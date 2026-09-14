#!/usr/bin/env bash
# Existing machine? Inventory what is already there, ask keep/archive/replace per item, remember the answers.
# Called by bootstrap.sh after the clone; safe to run alone. No tty = safe defaults, nothing asked.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
DECISIONS="$STATE/preflight"
ARCHIVE="$STATE/archive/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$STATE"
touch "$DECISIONS"

step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }
decided() { sed -n "s|^$1=||p" "$DECISIONS" | tail -1; }

# ask KEY QUESTION DEFAULT "safe-opt opt2 ..." -> prints the answer. Remembered answers are reused; no tty picks the first option.
ask() {
  local key=$1 q=$2 default=$3 opts=$4 choice o
  choice=$(decided "$key")
  if [ -n "$choice" ]; then echo "$choice"; return; fi
  if { : </dev/tty; } 2>/dev/null; then
    while :; do
      printf '%s\n  %s [%s]: ' "$q" "${opts// //}" "$default" >/dev/tty
      read -r choice </dev/tty || choice=$default
      choice=${choice:-$default}
      for o in $opts; do case $o in "$choice"*) choice=$o; break 2 ;; esac; done
      echo "  answer with one of: $opts" >/dev/tty
    done
  else
    choice=${opts%% *}
    echo "no tty: $q -> $choice"
  fi
  printf '%s=%s\n' "$key" "$choice" >>"$DECISIONS"
  echo "$choice"
}

archive() {
  local rel=${1#"$HOME"/}
  mkdir -p "$ARCHIVE/$(dirname "$rel")"
  mv "$1" "$ARCHIVE/$rel"
  echo "archived   $1 -> $ARCHIVE/$rel"
}

ours() { [ -L "$1" ] && [[ $(readlink "$1") == "$REPO/"* ]]; }

step "shell files in \$HOME"
for f in .zshrc .zprofile .zlogin .zshenv .oh-my-zsh .bashrc .bash_profile; do
  p="$HOME/$f"
  { [ -e "$p" ] || [ -L "$p" ]; } || continue
  ours "$p" && continue
  case $f in
    .bash*) q="$p exists; bash still reads it, zsh never will" d=keep ;;
    *)      q="$p exists; zsh reads only ~/.zshenv from \$HOME once ZDOTDIR is set, so it is dead weight" d=archive ;;
  esac
  case $(ask "shell/$f" "$q" "$d" "keep archive") in
    archive) archive "$p" ;;
    keep)    echo "kept       $p" ;;
  esac
done

step "emacs"
for f in .emacs .emacs.el .emacs.d; do
  p="$HOME/$f"
  [ -e "$p" ] || continue
  case $(ask "emacs/$f" "$p exists; Emacs loads it and ignores ~/.config/emacs while it is there" archive "keep archive") in
    archive) archive "$p" ;;
    keep)    echo "kept       $p  (the repo Emacs config will not load)" ;;
  esac
done
if [ "$(uname -s)" = Darwin ] && command -v brew >/dev/null && ! brew list --formula 2>/dev/null | grep -qx 'emacs-plus@30'; then
  have=""
  [ -d /Applications/Emacs.app ] && have="/Applications/Emacs.app"
  brew list --formula 2>/dev/null | grep -qx emacs && have="$have brew:emacs"
  brew list --cask 2>/dev/null | grep -qx emacs && have="$have cask:emacs"
  if [ -n "$have" ]; then
    case $(ask emacs/install "Emacs is already installed ($have); the repo installs emacs-plus@30 and runs it as a daemon" keep "keep replace") in
      keep)    echo "kept       $have  (emacs-plus@30 skipped; run your own daemon: emacs --daemon)" ;;
      replace) echo "replacing  emacs-plus@30 will be installed; remove the old one yourself: brew uninstall emacs, rm -r /Applications/Emacs.app" ;;
    esac
  fi
fi

step "git"
[ -f "$HOME/.gitconfig" ] && echo "note       ~/.gitconfig is read after ~/.config/git/config, so everything in it (identity, signing, helpers) overrides the repo defaults; it is left alone"

step "claude code"
have=""
for f in CLAUDE.md settings.json statusline.sh output-styles skills; do
  p="$HOME/.claude/$f"
  { [ -e "$p" ] || [ -L "$p" ]; } || continue
  ours "$p" && continue
  have="$have $f"
done
if [ -n "$have" ]; then
  grep -qs '"hooks"' "$HOME/.claude/settings.json" && echo "note       ~/.claude/settings.json has a hooks block; the repo settings.json has none"
  case $(ask claude/config "~/.claude already has$have" keep "keep replace") in
    keep)    echo "kept       ~/.claude  (install.sh skips the claude group)" ;;
    replace) echo "replacing  install.sh archives them and links the repo copies" ;;
  esac
fi

step "toolchain managers"
for d in .nvm .pyenv .rbenv .asdf; do
  [ -d "$HOME/$d" ] && echo "note       ~/$d exists; mise covers the same job (mise use node@lts, python@3.x); remove it when you are ready"
done

echo
echo "answers saved in $DECISIONS; delete a line to be asked again"
[ -d "$ARCHIVE" ] && echo "archived files are in $ARCHIVE"
exit 0
