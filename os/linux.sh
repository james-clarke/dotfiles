#!/usr/bin/env bash
# Debian 13 + KDE packages, Emacs daemon, Ghostty, Claude Code, fonts. Idempotent. Called by bootstrap.sh.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BIN="$HOME/.local/bin"
GHOSTTY_TAG=1.3.1-0-ppa2
GHOSTTY_SHA256_amd64=9fda8e418d7a7f58149ba3ba823a255d6b80f8bb5431b3bd7e912ff597715b2e
GHOSTTY_SHA256_arm64=73f384e62c419d7a7809d686bf579fea5e23f52742b34f70c74d6adf0e72f8ab
NERD_FONTS_TAG=v3.5.1
CLAUDE_KEY_FPR=31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE
step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

step "apt"
sudo apt-get update -q
xargs -a "$REPO/os/apt-packages.txt" sudo apt-get install -y -q
case ${XDG_SESSION_TYPE:-} in wayland) EMACS=emacs-pgtk ;; *) EMACS=emacs-gtk ;; esac
sudo apt-get install -y -q "$EMACS"
mkdir -p "$BIN"
ln -sfn /usr/bin/batcat "$BIN/bat"
ln -sfn /usr/bin/fdfind "$BIN/fd"

step "mise (apt via extrepo; updates ride apt upgrade)"
if ! command -v mise >/dev/null; then
  sudo apt-get install -y -q extrepo
  sudo extrepo enable mise
  sudo apt-get update -q
  sudo apt-get install -y -q mise
fi

step "font"
FONTS="$HOME/.local/share/fonts/CommitMonoNerdFont"
if [ ! -d "$FONTS" ]; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/font.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONTS_TAG/CommitMono.zip"
  mkdir -p "$FONTS"
  unzip -q -o "$tmp/font.zip" -d "$FONTS" -x LICENSE README.md
  fc-cache -f
fi

step "ghostty"
if ! command -v ghostty >/dev/null; then
  codename=$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release)
  arch=$(dpkg --print-architecture)
  deb="ghostty_${GHOSTTY_TAG%-*}.${GHOSTTY_TAG##*-}_${arch}_${codename}.deb"
  sum="GHOSTTY_SHA256_$arch"
  tmp=$(mktemp -d)
  if [ "$codename" = trixie ] && [ -n "${!sum:-}" ] \
     && curl -fsSL -o "$tmp/$deb" "https://github.com/mkasberg/ghostty-ubuntu/releases/download/$GHOSTTY_TAG/$deb"; then
    echo "${!sum}  $tmp/$deb" | sha256sum -c --quiet || { echo "ghostty checksum mismatch"; exit 1; }
    sudo apt-get install -y -q "$tmp/$deb"
  else
    echo "no verified ghostty build for $codename/$arch; konsole stays the terminal"
  fi
fi

step "emacs daemon"
systemctl --user enable --now emacs.service \
  || echo "no user session (ssh / before first login); after login run: systemctl --user enable --now emacs.service"

step "claude code (apt; updates ride apt upgrade)"
if ! command -v claude >/dev/null; then
  sudo install -d -m 0755 /etc/apt/keyrings
  sudo curl -fsSL https://downloads.claude.ai/keys/claude-code.asc -o /etc/apt/keyrings/claude-code.asc
  gpg --show-keys --with-colons /etc/apt/keyrings/claude-code.asc | grep -q "^fpr:.*:$CLAUDE_KEY_FPR:" \
    || { echo "claude-code.asc fingerprint mismatch"; exit 1; }
  echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" \
    | sudo tee /etc/apt/sources.list.d/claude-code.list >/dev/null
  sudo apt-get update -q
  sudo apt-get install -y -q claude-code
fi

step "kde"
if command -v kwriteconfig6 >/dev/null && [ -n "${KDE_SESSION_VERSION:-}" ]; then
  "$REPO/kde/apply.sh"
else
  echo "not inside a Plasma session; run kde/apply.sh after login"
fi

step "login shell"
[ "$(getent passwd "$USER" | cut -d: -f7)" = /usr/bin/zsh ] || chsh -s /usr/bin/zsh
