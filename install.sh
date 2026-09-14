#!/usr/bin/env bash
# Symlink repo files into place. `install.sh check` verifies every link.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
case ${1:-install} in
  install) MODE="link" ;;
  check)   MODE="check" ;;
  *) echo "usage: install.sh [install|check]" >&2; exit 2 ;;
esac

LINKS=(
  "claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
  "claude/settings.json:$HOME/.claude/settings.json"
  "claude/statusline.sh:$HOME/.claude/statusline.sh"
  "claude/output-styles:$HOME/.claude/output-styles"
  "claude/skills:$HOME/.claude/skills"
  "config/git/config:$HOME/.config/git/config"
  "config/git/ignore:$HOME/.config/git/ignore"
  "config/mise/config.toml:$HOME/.config/mise/config.toml"
  "emacs/early-init.el:$HOME/.config/emacs/early-init.el"
  "emacs/init.el:$HOME/.config/emacs/init.el"
  "ghostty/config:$HOME/.config/ghostty/config"
  "zsh:$HOME/.config/zsh"
  "zsh/home.zshenv:$HOME/.zshenv"
)
case $(uname -s) in
  Linux) LINKS+=(
    "kde/env.sh:$HOME/.config/plasma-workspace/env/dotfiles.sh"
    "kde/dotfiles-emacs.desktop:$HOME/.local/share/applications/dotfiles-emacs.desktop"
  ) ;;
esac

link() {
  local src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%s)"
    echo "backed up  $dst"
  fi
  ln -s "$src" "$dst"
  echo "linked     $dst"
}

check() {
  local src=$1 dst=$2
  if [ "$(readlink "$dst" 2>/dev/null)" = "$src" ]; then echo "ok         $dst"
  else echo "DRIFT      $dst"; rc=1; fi
}

rc=0
for pair in "${LINKS[@]}"; do
  src="$REPO/${pair%%:*}" dst="${pair#*:}"
  "$MODE" "$src" "$dst"
done
[ "$MODE" = check ] && exit "$rc"

MANIFEST="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/links"
if [ -f "$MANIFEST" ]; then
  while read -r old; do
    case " ${LINKS[*]#*:} " in *" $old "*) continue ;; esac
    [ -L "$old" ] && [[ $(readlink "$old") == "$REPO/"* ]] && { rm "$old"; echo "pruned     $old"; }
  done < "$MANIFEST"
fi
mkdir -p "$(dirname "$MANIFEST")"
printf '%s\n' "${LINKS[@]#*:}" > "$MANIFEST"

LOCAL="$HOME/.config/git/config.local"
if [ ! -f "$LOCAL" ]; then
  printf '[user]\n\tname = \n\temail = \n\tsigningkey = ~/.ssh/id_ed25519.pub\n' > "$LOCAL"
  echo "created    $LOCAL  <- fill in name/email"
fi
