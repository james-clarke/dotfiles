#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BIN="$HOME/.local/bin"
GHOSTTY_TAG=1.3.1-0-ppa2
GHOSTTY_SHA256_amd64=9fda8e418d7a7f58149ba3ba823a255d6b80f8bb5431b3bd7e912ff597715b2e
GHOSTTY_SHA256_arm64=73f384e62c419d7a7809d686bf579fea5e23f52742b34f70c74d6adf0e72f8ab
NERD_FONTS_TAG=v3.5.1
CLAUDE_KEY_FPR=31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE
step() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
sudo -v

step "apt"
sudo apt-get update -q
xargs -a "$REPO/os/apt-packages.txt" sudo apt-get install -y -q
sudo apt-get upgrade -y -q
mkdir -p "$BIN"
ln -sfn /usr/bin/batcat "$BIN/bat"
ln -sfn /usr/bin/fdfind "$BIN/fd"

step "uv and npm tools"
export PATH="$BIN:$PATH" npm_config_prefix="$HOME/.local"
command -v uv >/dev/null || pipx install uv
pipx upgrade-all
while read -r t; do uv tool install "$t"; done < "$REPO/os/uv-tools.txt"
uv tool upgrade --all
xargs -a "$REPO/os/npm-packages.txt" npm install -g

step "font"
FONTS="$HOME/.local/share/fonts/CommitMonoNerdFont"
if [ ! -d "$FONTS" ]; then
  curl -fsSL -o "$tmp/font.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONTS_TAG/CommitMono.zip"
  mkdir -p "$FONTS"
  unzip -q -o "$tmp/font.zip" -d "$FONTS" -x LICENSE README.md
  fc-cache -f
fi

step "ghostty"
want="${GHOSTTY_TAG%-*}.${GHOSTTY_TAG##*-}"
have=$(dpkg-query -W -f='${Version}' ghostty 2>/dev/null || true)
if [ "$have" != "$want" ]; then
  codename=$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release)
  arch=$(dpkg --print-architecture)
  deb="ghostty_${want}_${arch}_${codename}.deb"
  case $arch in
    amd64) sum=$GHOSTTY_SHA256_amd64 ;;
    arm64) sum=$GHOSTTY_SHA256_arm64 ;;
    *) sum= ;;
  esac
  if [ "$codename" = trixie ] && [ -n "$sum" ] \
     && curl -fsSL -o "$tmp/$deb" "https://github.com/mkasberg/ghostty-ubuntu/releases/download/$GHOSTTY_TAG/$deb"; then
    echo "$sum  $tmp/$deb" | sha256sum -c --quiet || { echo "ghostty checksum mismatch"; exit 1; }
    sudo apt-get install -y -q "$tmp/$deb"
  else
    echo "no verified ghostty build for $codename/$arch; konsole stays the terminal"
  fi
fi

step "emacs daemon"
systemctl --user enable --now emacs.service \
  || echo "no user session (ssh / before first login); after login run: systemctl --user enable --now emacs.service"

step "claude code"
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

step "login shell"
[ "$(getent passwd "$(id -un)" | cut -d: -f7)" = /usr/bin/zsh ] || chsh -s /usr/bin/zsh
