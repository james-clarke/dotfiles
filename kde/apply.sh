#!/usr/bin/env bash
set -euo pipefail

set_key() {
	local file=$1 groups=$2 key=$3 value=$4 args=()
	local g
	IFS=/ read -ra g <<<"$groups"
	for x in "${g[@]}"; do args+=(--group "$x"); done
	kwriteconfig6 --file "$file" "${args[@]}" --key "$key" "$value"
}

set_key kxkbrc Layout Options ctrl:swapcaps
set_key kxkbrc Layout ResetOldOptions true
set_key kcminputrc Keyboard RepeatDelay 250
set_key kcminputrc Keyboard RepeatRate 40

set_key kdeglobals General fixed 'CommitMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1'

term=org.kde.konsole.desktop
command -v ghostty >/dev/null && term=com.mitchellh.ghostty.desktop
set_key kglobalshortcutsrc "services/$term" _launch 'Meta+Return'
set_key kglobalshortcutsrc services/dotfiles-emacs.desktop _launch 'Meta+E'
set_key kglobalshortcutsrc services/org.kde.krunner.desktop _launch 'Meta+D'

set_key kglobalshortcutsrc kwin 'Window Close' 'Meta+Shift+Q,Alt+F4,Close Window'
set_key kglobalshortcutsrc kwin 'Window to Previous Screen' 'none,Meta+Shift+Left,Move Window to Previous Screen'
set_key kglobalshortcutsrc kwin 'Window to Next Screen' 'none,Meta+Shift+Right,Move Window to Next Screen'
set_key kglobalshortcutsrc kwin 'Switch Window Left' 'Meta+Left,Meta+Alt+Left,Switch to Window to the Left'
set_key kglobalshortcutsrc kwin 'Switch Window Down' 'Meta+Down,Meta+Alt+Down,Switch to Window Below'
set_key kglobalshortcutsrc kwin 'Switch Window Up' 'Meta+Up,Meta+Alt+Up,Switch to Window Above'
set_key kglobalshortcutsrc kwin 'Switch Window Right' 'Meta+Right,Meta+Alt+Right,Switch to Window to the Right'
set_key kglobalshortcutsrc kwin 'Window Quick Tile Left' 'Meta+Shift+Left,Meta+Left,Quick Tile Window to the Left'
set_key kglobalshortcutsrc kwin 'Window Quick Tile Bottom' 'Meta+Shift+Down,Meta+Down,Quick Tile Window to the Bottom'
set_key kglobalshortcutsrc kwin 'Window Quick Tile Top' 'Meta+Shift+Up,Meta+Up,Quick Tile Window to the Top'
set_key kglobalshortcutsrc kwin 'Window Quick Tile Right' 'Meta+Shift+Right,Meta+Right,Quick Tile Window to the Right'
set_key kglobalshortcutsrc kwin 'Window Maximize' $'Meta+F\tMeta+PgUp,Meta+PgUp,Maximize Window'
set_key kglobalshortcutsrc kwin 'Window Fullscreen' 'Meta+Shift+F,,Make Window Fullscreen'

! command -v kbuildsycoca6 >/dev/null || kbuildsycoca6 >/dev/null 2>&1 || true
! command -v qdbus6 >/dev/null || qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true
echo "applied. Keyboard options and shortcuts fully apply on next login."
