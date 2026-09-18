#!/usr/bin/env bash
set -euo pipefail

set_key() { # FILE GROUP[/SUBGROUP...] KEY VALUE
  local file=$1 groups=$2 key=$3 value=$4 args=()
  local g; IFS=/ read -ra g <<<"$groups"
  for x in "${g[@]}"; do args+=(--group "$x"); done
  kwriteconfig6 --file "$file" "${args[@]}" --key "$key" "$value"
}

# keyboard
set_key kxkbrc Layout Options caps:swapctrl
set_key kxkbrc Layout ResetOldOptions true
set_key kcminputrc Keyboard RepeatDelay 250
set_key kcminputrc Keyboard RepeatRate 40

# fonts
set_key kdeglobals General fixed 'CommitMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1'

# launchers: Plasma 6 stores .desktop shortcuts under [services][id] as a bare key sequence
term=org.kde.konsole.desktop
command -v ghostty >/dev/null && term=com.mitchellh.ghostty.desktop
set_key kglobalshortcutsrc "services/$term" _launch 'Meta+Return'
set_key kglobalshortcutsrc services/dotfiles-emacs.desktop _launch 'Meta+E'
set_key kglobalshortcutsrc services/org.kde.krunner.desktop _launch 'Meta+D'

# kwin
set_key kglobalshortcutsrc kwin 'Window Close'        'Meta+Shift+Q,Alt+F4,Close Window'
set_key kglobalshortcutsrc kwin 'Switch Window Left'  'Meta+H,,Switch to Window to the Left'
set_key kglobalshortcutsrc kwin 'Switch Window Down'  'Meta+J,,Switch to Window Below'
set_key kglobalshortcutsrc kwin 'Switch Window Up'    'Meta+K,,Switch to Window Above'
set_key kglobalshortcutsrc kwin 'Switch Window Right' 'Meta+L,,Switch to Window to the Right'
set_key kglobalshortcutsrc kwin 'Window Quick Tile Left'   $'Meta+Shift+H\tMeta+Left,Meta+Left,Quick Tile Window to the Left'
set_key kglobalshortcutsrc kwin 'Window Quick Tile Bottom' $'Meta+Shift+J\tMeta+Down,Meta+Down,Quick Tile Window to the Bottom'
set_key kglobalshortcutsrc kwin 'Window Quick Tile Top'    $'Meta+Shift+K\tMeta+Up,Meta+Up,Quick Tile Window to the Top'
set_key kglobalshortcutsrc kwin 'Window Quick Tile Right'  $'Meta+Shift+L\tMeta+Right,Meta+Right,Quick Tile Window to the Right'
set_key kglobalshortcutsrc kwin 'Window Maximize'          $'Meta+F\tMeta+PgUp,Meta+PgUp,Maximize Window'
set_key kglobalshortcutsrc kwin 'Window Fullscreen'        'Meta+Shift+F,,Make Window Fullscreen'

# reload; kglobalaccel does not hot-reload reliably, logout is the fallback
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true
command -v qdbus6 >/dev/null && qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true
echo "applied. Keyboard options and shortcuts fully apply on next login."
