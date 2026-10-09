#!/usr/bin/env bash
# Safe to re-run.
# --links-only: refresh symlinks, install nothing.
set -euo pipefail
cd "$(dirname "$0")"

links_only=0
if [ "${1:-}" = --links-only ]; then links_only=1; fi

# symlink target to repo file
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

# login shell
current_shell() {
  if [ "$(uname)" = Darwin ]; then
    dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}'
  else
    getent passwd "$(id -un)" | cut -d: -f7
  fi
}

# make links
link bash/bashrc ~/.bashrc
link bash/bash_profile ~/.bash_profile
link git/config ~/.config/git/config
link git/ignore ~/.config/git/ignore
link claude/settings.json ~/.claude/settings.json
link opencode/opencode.json ~/.config/opencode/opencode.json
link ssh/config ~/.ssh/config
chmod 700 ~/.ssh
# vscode
if [ "$(uname)" = Darwin ]; then
  link vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
else
  link vscode/settings.json ~/.config/Code/User/settings.json
fi
# done check
if [ "$links_only" = 1 ]; then
  echo "Links only. Nothing installed."
  exit 0
fi

mkdir -p ~/Developer

if [ "$(uname)" = Linux ]; then
  sudo apt-get update
  sudo apt-get install -y curl gpg
  sudo install -d -m 0755 /etc/apt/keyrings

  # Claude Code, VS Code, Google Chrome, Tailscale
  sudo curl -fsSL -o /etc/apt/keyrings/claude-code.asc https://downloads.claude.ai/keys/claude-code.asc
  echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" |
    sudo tee /etc/apt/sources.list.d/claude-code.list >/dev/null

  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null
  printf '%s\n' "Types: deb" "URIs: https://packages.microsoft.com/repos/code" "Suites: stable" "Components: main" \
    "Architectures: amd64,arm64,armhf" "Signed-By: /etc/apt/keyrings/microsoft.gpg" |
    sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null

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

  if [ -f /etc/apt/sources.list.d/google-chrome.sources ]; then
    sudo rm -f /etc/apt/sources.list.d/google-chrome.list /etc/apt/keyrings/google-chrome.gpg
  fi

  sudo systemctl enable --now ssh

  # opencode
  npm_config_prefix="$HOME/.local" npm install -g opencode-ai

  # caps -> ctrl
  printf '[ids]\n*\n\n[main]\ncapslock = leftcontrol\nleftcontrol = capslock\n' | sudo tee /etc/keyd/default.conf >/dev/null
  sudo systemctl enable keyd
  sudo systemctl restart keyd

  # key repeat, default browser, login shell
  kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatDelay 250
  kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatRate 40
  xdg-settings set default-web-browser google-chrome.desktop
  [ "$(current_shell)" = /bin/bash ] || sudo chsh -s /bin/bash "$(id -un)"

  echo "Done. Log out and back in. First time only: sudo tailscale up, ssh-copy-id macstation, opencode auth login"
else
  if ! command -v brew >/dev/null; then
    # grab brew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew_bin=""
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then brew_bin="$candidate"; break; fi
  done
  if [ -z "$brew_bin" ]; then echo "brew not found after install" >&2; exit 1; fi
  eval "$("$brew_bin" shellenv)"

  brew install bash git gh jq node
  brew install --cask visual-studio-code google-chrome tailscale-app claude-code
  code --install-extension ms-vscode-remote.remote-ssh
  sudo systemsetup -setremotelogin on

  # opencode
  npm_config_prefix="$HOME/.local" npm install -g opencode-ai

  # login shell
  brew_bash="$(brew --prefix)/bin/bash"
  grep -qx "$brew_bash" /etc/shells || echo "$brew_bash" | sudo tee -a /etc/shells >/dev/null
  [ "$(current_shell)" = "$brew_bash" ] || chsh -s "$brew_bash"

  # caps -> ctrl, key repeat
  mkdir -p ~/Library/LaunchAgents
  cp macos/capslock.plist ~/Library/LaunchAgents/com.dotfiles.capslock.plist
  launchctl bootout "gui/$(id -u)/com.dotfiles.capslock" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.dotfiles.capslock.plist
  defaults write -g KeyRepeat -int 1
  defaults write -g InitialKeyRepeat -int 10
  defaults write -g ApplePressAndHoldEnabled -bool false

  echo "Done. Log out and back in. First time only: open Tailscale and sign in, then: ssh-copy-id debstation, opencode auth login"
fi
