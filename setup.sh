#!/usr/bin/env bash
# Set up a fresh Debian 13 KDE box or a Mac from this repo. Safe to run again.
# --links-only: just refresh the symlinks, install nothing (used by CI).
set -euo pipefail
cd "$(dirname "$0")"

links_only=0
if [ "${1:-}" = --links-only ]; then links_only=1; fi

# link <repo file> <target>: symlink target to the repo file. A real file already
# there moves to <target>.bak, or <target>.bak.<timestamp> if that is taken too.
link() {
  mkdir -p "$(dirname "$2")"
  if [ -e "$2" ] && [ ! -L "$2" ]; then
    bak="$2.bak"
    if [ -e "$bak" ]; then bak="$2.bak.$(date +%Y%m%d%H%M%S)"; fi
    mv "$2" "$bak"
    echo "moved      $2 -> $bak"
  fi
  ln -sfn "$PWD/$1" "$2"
}

# The login shell recorded for this user, per OS (macOS has no getent).
current_shell() {
  if [ "$(uname)" = Darwin ]; then
    dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}'
  else
    getent passwd "$(id -un)" | cut -d: -f7
  fi
}

link bash/bashrc ~/.bashrc
link bash/bash_profile ~/.bash_profile
link git/config ~/.config/git/config
link git/ignore ~/.config/git/ignore
link claude/settings.json ~/.claude/settings.json

if [ "$(uname)" = Darwin ]; then
  link vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
  link ssh/config ~/.ssh/config
  chmod 700 ~/.ssh
else
  link vscode/settings.json ~/.config/Code/User/settings.json
fi

if [ "$links_only" = 1 ]; then
  echo "Links only. Nothing installed."
  exit 0
fi

# Code lives in ~/Developer on both machines.
mkdir -p ~/Developer

if [ "$(uname)" = Linux ]; then
  sudo apt-get update
  sudo apt-get install -y curl gpg
  sudo install -d -m 0755 /etc/apt/keyrings

  # apt repos: Claude Code, VS Code, Google Chrome, Tailscale. Keys all in /etc/apt/keyrings.
  sudo curl -fsSL -o /etc/apt/keyrings/claude-code.asc https://downloads.claude.ai/keys/claude-code.asc
  echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" |
    sudo tee /etc/apt/sources.list.d/claude-code.list >/dev/null

  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null
  printf '%s\n' "Types: deb" "URIs: https://packages.microsoft.com/repos/code" "Suites: stable" "Components: main" \
    "Architectures: amd64,arm64,armhf" "Signed-By: /etc/apt/keyrings/microsoft.gpg" |
    sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null

  # Google Chrome, not Chromium: Debian's Chromium has browser sign-in patched out
  # (disable/signin.patch), so signing in to a work Google profile cannot work there.
  # This repo is only a bootstrap; the package replaces it with its own, and the
  # key and list below are retired right after the install.
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/google-chrome.gpg >/dev/null
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" |
    sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null

  . /etc/os-release
  curl -fsSL "https://pkgs.tailscale.com/stable/debian/$VERSION_CODENAME.noarmor.gpg" |
    sudo tee /etc/apt/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL "https://pkgs.tailscale.com/stable/debian/$VERSION_CODENAME.tailscale-keyring.list" |
    sed 's#/usr/share/keyrings/#/etc/apt/keyrings/#' |
    sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null

  sudo chmod 0644 /etc/apt/keyrings/*

  sudo apt-get update
  sudo apt-get install -y git gh jq nodejs npm code google-chrome-stable openssh-server tailscale claude-code keyd

  # google-chrome-stable installs and maintains its own google-chrome.sources, signed
  # by its own keyring. Drop the bootstrap pair so no dangling key or list is left.
  if [ -f /etc/apt/sources.list.d/google-chrome.sources ]; then
    sudo rm -f /etc/apt/sources.list.d/google-chrome.list /etc/apt/keyrings/google-chrome.gpg
  fi

  sudo systemctl enable --now ssh

  # Caps Lock <-> Left Ctrl
  printf '[ids]\n*\n\n[main]\ncapslock = leftcontrol\nleftcontrol = capslock\n' | sudo tee /etc/keyd/default.conf >/dev/null
  sudo systemctl enable keyd
  sudo systemctl restart keyd

  # key repeat (next login), default browser, login shell
  kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatDelay 250
  kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatRate 40
  xdg-settings set default-web-browser google-chrome.desktop
  [ "$(current_shell)" = /bin/bash ] || sudo chsh -s /bin/bash "$(id -un)"

  echo "Done. Log out and back in. First time only: sudo tailscale up"
else
  if ! command -v brew >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Apple Silicon puts brew in /opt/homebrew, Intel in /usr/local.
  brew_bin=""
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then brew_bin="$candidate"; break; fi
  done
  if [ -z "$brew_bin" ]; then echo "brew not found after install" >&2; exit 1; fi
  eval "$("$brew_bin" shellenv)"

  brew install bash git gh jq node
  brew install --cask visual-studio-code google-chrome tailscale-app claude-code
  code --install-extension ms-vscode-remote.remote-ssh

  # login shell: Homebrew bash (macOS ships bash 3.2)
  brew_bash="$(brew --prefix)/bin/bash"
  grep -qx "$brew_bash" /etc/shells || echo "$brew_bash" | sudo tee -a /etc/shells >/dev/null
  [ "$(current_shell)" = "$brew_bash" ] || chsh -s "$brew_bash"

  # Caps Lock <-> Left Ctrl at every login, fast key repeat
  mkdir -p ~/Library/LaunchAgents
  cp macos/capslock.plist ~/Library/LaunchAgents/com.dotfiles.capslock.plist
  launchctl bootout "gui/$(id -u)/com.dotfiles.capslock" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.dotfiles.capslock.plist
  defaults write -g KeyRepeat -int 1
  defaults write -g InitialKeyRepeat -int 10
  defaults write -g ApplePressAndHoldEnabled -bool false

  echo "Done. Log out and back in. First time only: open Tailscale and sign in, then: ssh-copy-id debstation"
fi
