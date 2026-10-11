#!/usr/bin/env bash
# Links configs from this repo into $HOME. Installs nothing.
# If a tool is missing it prints the install command and stops; install, re-run.
# Usage: ./setup.sh [component...]    components: bash git ssh vscode opencode claude system
#        no args = default set for this OS. Re-run anytime to re-sync links.
set -euo pipefail
cd "$(dirname "$0")"

mac=0; [ "$(uname)" = Darwin ] && mac=1
bp=/opt/homebrew; [ -d $bp ] || bp=/usr/local   # brew prefix
export PATH="$HOME/.local/bin:$bp/bin:$PATH"
export npm_config_prefix="$HOME/.local"
if [ $# -eq 0 ]; then
  if [ $mac = 1 ]; then set -- bash git ssh vscode opencode system   # personal
  else set -- bash git ssh vscode claude system; fi                   # work
fi
[ "$1" = all ] && set -- bash git ssh vscode opencode claude system

# link repo/file target: replaces whatever is there, no backups
link() { mkdir -p "$(dirname "$2")"; ln -sfn "$PWD/$1" "$2"; }

# pkg cmd-or-path mac-spec linux-spec   (spec = manager:package)
brew="" cask="" apt="" npm=""
pkg() {
  case $1 in */*) [ -e "$1" ] && return 0 ;; *) command -v "$1" >/dev/null && return 0 ;; esac
  if [ $mac = 1 ]; then spec=$2; else spec=$3; fi
  case ${spec%%:*} in
    brew) brew="$brew ${spec#*:}" ;;  cask) cask="$cask ${spec#*:}" ;;
    apt)  apt="$apt ${spec#*:}" ;;    npm)  npm="$npm ${spec#*:}" ;;
  esac
}

current_shell() {
  if [ $mac = 1 ]; then dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}'
  else getent passwd "$(id -un)" | cut -d: -f7; fi
}

for c in "$@"; do
  case $c in
    bash)
      link bash/bashrc ~/.bashrc
      link bash/bash_profile ~/.bash_profile
      [ $mac = 1 ] && pkg $bp/bin/bash brew:bash - ;;
    git)
      link git/config ~/.config/git/config
      link git/ignore ~/.config/git/ignore
      pkg git brew:git apt:git
      pkg gh  brew:gh  apt:gh ;;
    ssh)
      link ssh/config ~/.ssh/config
      chmod 700 ~/.ssh ;;
    vscode)
      if [ $mac = 1 ]; then link vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
      else link vscode/settings.json ~/.config/Code/User/settings.json; fi
      pkg code cask:visual-studio-code apt:code ;;
    opencode)
      link opencode/opencode.json ~/.config/opencode/opencode.json
      pkg npm brew:node apt:npm
      pkg opencode npm:opencode-ai npm:opencode-ai ;;
    claude)
      link claude/settings.json ~/.claude/settings.json
      pkg claude cask:claude-code apt:claude-code ;;
    system)
      if [ $mac = 1 ]; then
        pkg /Applications/Tailscale.app cask:tailscale-app -
        pkg "/Applications/Google Chrome.app" cask:google-chrome -
      else
        pkg tailscale - apt:tailscale
        pkg google-chrome - apt:google-chrome-stable
        pkg /etc/keyd - apt:keyd   # debian names the binary keyd.rvaiya
        pkg /usr/sbin/sshd - apt:openssh-server
      fi ;;
    *) echo "unknown component: $c" >&2; exit 1 ;;
  esac
done

if [ -n "$brew$cask$apt$npm" ]; then
  echo; echo "Missing. Install, then re-run:"
  [ -n "$brew" ] && echo "  brew install$brew"
  [ -n "$cask" ] && echo "  brew install --cask$cask"
  [ -n "$apt" ]  && echo "  sudo apt install$apt      # third-party repos first: see README"
  [ -n "$npm" ]  && echo "  npm_config_prefix=\"\$HOME/.local\" npm install -g$npm"
  exit 1
fi

case " $* " in *" system "*) ;; *) echo "Linked."; exit 0 ;; esac

# system: idempotent OS settings. Caps->Ctrl, key repeat, sshd on, bash as login shell.
if [ $mac = 1 ]; then
  sudo systemsetup -setremotelogin on
  ! command -v code >/dev/null || code --install-extension ms-vscode-remote.remote-ssh >/dev/null
  mkdir -p ~/Library/LaunchAgents
  cp macos/capslock.plist ~/Library/LaunchAgents/com.dotfiles.capslock.plist
  launchctl bootout "gui/$(id -u)/com.dotfiles.capslock" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.dotfiles.capslock.plist
  defaults write -g KeyRepeat -int 1
  defaults write -g InitialKeyRepeat -int 10
  defaults write -g ApplePressAndHoldEnabled -bool false
  grep -qx $bp/bin/bash /etc/shells || echo $bp/bin/bash | sudo tee -a /etc/shells >/dev/null
  [ "$(current_shell)" = $bp/bin/bash ] || chsh -s $bp/bin/bash
else
  printf '[ids]\n*\n\n[main]\ncapslock = leftcontrol\nleftcontrol = capslock\n' | sudo tee /etc/keyd/default.conf >/dev/null
  sudo systemctl enable --now keyd ssh
  sudo systemctl restart keyd
  if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatDelay 250
    kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatRate 40
  fi
  xdg-settings set default-web-browser google-chrome.desktop
  [ "$(current_shell)" = /bin/bash ] || sudo chsh -s /bin/bash "$(id -un)"
fi
echo "Done. Log out and back in."
