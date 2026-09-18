# dotfiles

A lean development environment for a fresh **Debian 13 + KDE Plasma 6** or **macOS** machine, built around **Emacs** as a normal desktop editor (menu bar, mouse, `cua-mode`, vertico, eglot), a framework-free **zsh**, **Ghostty**, git, and **Claude Code** running inside Emacs as a read-only partner: it investigates, plans and walks you through, you type, `minuet` completes. One `curl` line sets up a new box on either OS; one command, `dots`, keeps every machine in sync afterwards. apt and Homebrew own every package, every config file is a symlink into this repo, and CI proves the shell and the Emacs config load cleanly on both platforms.

Nothing here is tied to a person or an employer. Fork it, change one URL, and it is yours.

---

## Contents

1. [What you get](#what-you-get)
2. [Install: Debian 13 + KDE](#install-debian-13--kde)
3. [Install: macOS](#install-macos)
4. [After bootstrap](#after-bootstrap)
5. [Repository layout](#repository-layout)
6. [How the pieces fit](#how-the-pieces-fit)
7. [Emacs](#emacs)
8. [Shell](#shell)
9. [Terminal: Ghostty](#terminal-ghostty)
10. [Git](#git)
11. [Toolchains](#toolchains)
12. [KDE](#kde)
13. [macOS specifics](#macos-specifics)
14. [Claude Code](#claude-code)
15. [Upgrading: dots](#upgrading-dots)
16. [Verification and CI](#verification-and-ci)
17. [Forking](#forking)
18. [Troubleshooting](#troubleshooting)

---

## What you get

| Area | Choice | Why |
|---|---|---|
| Editor | Emacs (30 on Debian, 31 on macOS), running as a daemon, `emacsclient` frames | Instant frames, one process, same config on both OSes |
| Keys | Stock Emacs keys + `cua-mode`, `C-c` command groups (which-key) | `Ctrl+C/V/X/Z` do what every other app does; the rest is Emacs as documented |
| UI | Menu bar, tool bar, scroll bars, right-click menu, tab bar, buffer tabs, drag and drop | A traditional desktop editor, mouse first-class |
| Completion | vertico, orderless, marginalia, consult, embark, corfu, cape | The current lean consensus stack; all small, all pure elisp |
| LSP | eglot (built-in) + treesit (built-in) | No lsp-mode, no UI sprawl; servers come from apt, Homebrew, `uv tool` and `npm -g` |
| Git in Emacs | magit, diff-hl | The reason to use Emacs |
| Formatting | apheleia | Async format-on-save, cursor stays put |
| Terminal in Emacs | eat | Pure elisp, no C module to compile |
| Shell | zsh, no framework | `~/.zshenv` stub + `~/.config/zsh/`; plugins as git submodules; cached tool init |
| Terminal | Ghostty | One config file for KDE and macOS; GPU fast; Meta passes through cleanly |
| Toolchains | apt / Homebrew; `uv tool` and `npm -g` under `~/.local` on Debian for what apt lacks | No version manager, no shims; upgrades ride the package manager |
| Git | delta pager, sane defaults | Identity, keys and signing stay whatever the machine already has |
| Fonts | CommitMono Nerd Font | Ligatures + icons, installed by bootstrap |
| AI | Claude Code CLI, `claude-code-ide.el`, `minuet` | Claude runs inside Emacs (`C-c a c`), sees your buffer and diagnostics, and cannot edit files: it investigates, plans and walks you through; you type. minuet gives ghost-text completion that reads the Claude window for context |
| Sync | `dots` | Pulls the repo, re-links, upgrades apt/Homebrew and the tools, restarts the Emacs daemon when its config changed |

Package counts stay small on purpose. Emacs pulls two dozen packages (plus their dependencies) from GNU ELPA, NonGNU ELPA and MELPA through the built-in `package.el`. There is no elpaca, straight, doom, or spacemacs layer.

---

## Install: Debian 13 + KDE

1. Install Debian 13 from the netinst with **KDE Plasma** and **standard system utilities**. Log in once so Plasma creates its config directories.

2. Set up git the way you normally would: `sudo apt install git`, `git config --global user.name` / `user.email`, and an SSH key registered on GitHub ([guide](https://docs.github.com/authentication/connecting-to-github-with-ssh)). `ssh -T git@github.com` must answer "successfully authenticated". The bootstrap checks all three and stops with the same instructions if any is missing; it never creates keys or touches `~/.gitconfig`.

3. Run the bootstrap:
   ```sh
   curl -fsSL https://raw.githubusercontent.com/james-clarke/dotfiles/master/bootstrap.sh | bash
   ```
   It checks git, your identity and SSH access to GitHub, installs `curl` if needed, clones this repo over SSH with submodules to `~/dev/dotfiles` (override with `DOTFILES_DIR`), and hands off to `bin/dots`. What `dots` does, in order:
   - links every config file into place ([Where things land](#where-things-land)); anything already there is renamed `<file>.bak`;
   - runs `os/linux.sh`:
     - `apt-get update`, installs everything in `os/apt-packages.txt` (including `emacs-pgtk`, `nodejs`, `npm`, `pipx`, `shfmt`), then `apt-get upgrade`;
     - `pipx install uv`, then `uv tool install` for `os/uv-tools.txt` (`ruff`, `basedpyright`) and `npm install -g` for `os/npm-packages.txt` (`typescript`, `typescript-language-server`, `prettier`), all under `~/.local`, no sudo;
     - downloads CommitMono Nerd Font into `~/.local/share/fonts` and refreshes the font cache;
     - installs Ghostty from the community `.deb` build (pinned version and SHA-256) or leaves Konsole in place if no build exists for your Debian codename;
     - enables the Emacs daemon as a systemd user service;
     - adds the Claude Code apt repository (GPG fingerprint verified) and installs `claude-code`;
     - sets zsh as the login shell;
   - runs `kde/apply.sh` if you are inside a Plasma session (otherwise it tells you to run it after login);
   - remembers the commit it applied, so later runs only restart the daemon or re-apply KDE settings when those files changed.

4. Log out and back in. This activates the zsh login shell, the Plasma session environment (`EDITOR`, `PATH`), the keyboard remap and the global shortcuts.

5. Continue at [After bootstrap](#after-bootstrap).

---

## Install: macOS

1. Have git set up: `xcode-select --install` provides it, then `git config --global user.name` / `user.email` and an SSH key registered on GitHub ([guide](https://docs.github.com/authentication/connecting-to-github-with-ssh)). `ssh -T git@github.com` must answer "successfully authenticated". The bootstrap checks and stops otherwise; it never creates keys or touches `~/.gitconfig`.

2. Run the bootstrap:
   ```sh
   curl -fsSL https://raw.githubusercontent.com/james-clarke/dotfiles/master/bootstrap.sh | bash
   ```
   It checks git, your identity and SSH access to GitHub, installs Xcode Command Line Tools if missing (the script exits and asks you to re-run once the installer finishes), installs Homebrew if missing, clones the repo over SSH with submodules to `~/Developer/dotfiles` (Finder gives that folder its own icon; `DEV_DIR` or `DOTFILES_DIR` override; the rest of this README writes `~/dev/dotfiles`), and hands off to `bin/dots`. What `dots` does, in order:
   - links every config file into place; anything already there is renamed `<file>.bak`;
   - runs `os/macos.sh`:
     - `brew update`, `brew bundle` against `os/Brewfile`, `brew upgrade`, `brew autoremove`, `brew cleanup`. Formulas: `git`, `node`, `uv`, `ruff`, `shfmt`, `basedpyright`, `typescript-language-server`, `typescript`, `prettier`, `jq`, `fzf`, `eza`, `zoxide`, `ripgrep`, `fd`, `bat`, `git-delta`, `direnv`, `shellcheck`. Casks: `emacs-app` (jimeh/emacs-builds: signed, notarized, native-comp, Emacs 31), Ghostty, Claude Code, the Nerd Font;
     - installs a LaunchAgent (`com.dotfiles.emacs`) that runs `/Applications/Emacs.app` as `--fg-daemon` and keeps it alive;
     - installs a LaunchAgent that swaps Caps Lock and Left Ctrl at every login (`hidutil`);
     - adds `AddKeysToAgent` / `UseKeychain` to `~/.ssh/config`;
     - makes `/bin/zsh` the login shell if it is not;
     - fixes the Homebrew completion-directory permissions that otherwise trigger `compinit` warnings;
   - applies `os/macos/defaults.sh` (fast key repeat, no press-and-hold accents, no smart quotes, Finder shows extensions and hidden files, Dock autohide) on the first run and whenever that file changes.

3. Log out and back in (or reboot) so the keyboard remap, key repeat and login shell environment apply everywhere.

4. Continue at [After bootstrap](#after-bootstrap).

---

## After bootstrap

1. Open a terminal (Ghostty). The prompt is `➜ dir git:(branch)`.

2. Log in to Claude Code and install the plugins the settings file expects:
   ```sh
   claude
   jq -r '.enabledPlugins | keys[]' ~/dev/dotfiles/claude/settings.json | xargs -n1 claude plugin install
   ```

3. Get an [OpenRouter](https://openrouter.ai/keys) API key: buy a few dollars of credit (Stripe checkout, Apple Pay works), create a key. Nothing to configure: the first time you press `M-i` in a code buffer, Emacs asks for the key in the minibuffer and offers to save it to `~/.authinfo` (mode 600). Until then minuet stays quiet and says so once per session. Prefer it encrypted? Write the line into `~/.authinfo.gpg` yourself instead:
   ```
   machine openrouter.ai login apikey password sk-or-v1-...
   ```

4. Verify that every symlink survived (Claude's `/model` command and some apps rewrite files; this catches it):
   ```sh
   dots check
   ```

5. Open Emacs: `Meta+E` on KDE, Spotlight → "Emacs" on macOS, or `e file` in any terminal. The first launch installs the Emacs packages, including a `git clone` of `claude-code-ide.el` (one to two minutes, once). Native compilation runs in the background afterwards; ignore the `*Async-native-compile-log*` buffer.

6. Linux only, if bootstrap ran outside a Plasma session: run `~/dev/dotfiles/kde/apply.sh` now, then log out and in.

---

## Repository layout

```
bootstrap.sh            curl entry point: checks git/SSH, installs curl or Xcode CLT + Homebrew, clones, runs bin/dots
bin/dots                sync command: pull, link, os/*.sh, daemon restart, KDE/defaults re-apply; `dots link`, `dots check`
os/
  linux.sh              Debian 13: apt, uv/npm tools, font, Ghostty, Emacs daemon, Claude Code, login shell
  macos.sh              Homebrew bundle + upgrade, Emacs and Caps Lock LaunchAgents, SSH keychain, login shell
  apt-packages.txt      flat apt list
  npm-packages.txt      npm -g list (Debian only; Homebrew formulas on macOS)
  uv-tools.txt          uv tool list (Debian only; Homebrew formulas on macOS)
  Brewfile              tap, formulas, casks
  macos/defaults.sh     curated `defaults write`
  macos/emacs.plist     LaunchAgent: Emacs.app --fg-daemon, KeepAlive
  macos/capslock.plist  LaunchAgent: Caps Lock <-> Left Ctrl
emacs/
  early-init.el         GC and frame settings applied before the GUI exists
  init.el               the whole Emacs config, one file
  templates             tempel snippets, a handful per mode
zsh/
  home.zshenv           the only file in $HOME; sets ZDOTDIR and sources the real .zshenv
  .zshenv               env for every zsh: XDG dirs, PATH (Homebrew, ~/.local/bin), EDITOR, npm prefix
  .zprofile             login shells: re-assert PATH order after macOS path_helper
  .zshrc                interactive: history, completion, prompt, plugins, tools, widgets
  plugins/              fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting (submodules)
ghostty/config          shared terminal config
config/
  git/config            git defaults; includes config.local for machine-specific overrides
  git/ignore            global gitignore
kde/
  apply.sh              Plasma settings via kwriteconfig6 (keyboard, fonts, shortcuts)
  env.sh                Plasma session env (PATH, EDITOR) for GUI apps
  dotfiles-emacs.desktop hidden launcher bound to Meta+E
claude/
  CLAUDE.md             global rules for Claude Code
  settings.json         permissions (read-only), plugins, statusline
  statusline.sh         model / effort / project / branch / context / rate-limit line
  skills/investigate/   /investigate: read-only brief of a ticket, PR or area
  skills/review/        /review: PR review and re-review, drafts only
.github/workflows/ci.yml  Linux (Debian container) + macOS checks
```

### Where things land

| Repo file | Symlink target |
|---|---|
| `bin/dots` | `~/.local/bin/dots` |
| `zsh/home.zshenv` | `~/.zshenv` |
| `zsh/` | `~/.config/zsh/` |
| `emacs/early-init.el`, `emacs/init.el`, `emacs/templates` | `~/.config/emacs/` (packages, `custom.el`, `eln-cache` live there too, untracked) |
| `ghostty/config` | `~/.config/ghostty/config` |
| `config/git/*` | `~/.config/git/` |
| `claude/*` | `~/.claude/` |
| `kde/env.sh` (Linux) | `~/.config/plasma-workspace/env/dotfiles.sh` |
| `kde/dotfiles-emacs.desktop` (Linux) | `~/.local/share/applications/` |

`dots` records the targets in `~/.local/state/dotfiles/links` and removes links from earlier runs whose entry has since left the table. Files that must not be symlinks (Plasma rewrites its rc files atomically, launchd wants a real plist) are written by `kde/apply.sh` and `os/macos.sh` instead.

---

## How the pieces fit

**Editor everywhere.** `EDITOR` and `VISUAL` are `emacsclient -t` in shells (a terminal frame inside your current terminal, fast, closes with `C-x #`), and `emacsclient -c` for GUI sessions (KDE via `kde/env.sh`; macOS apps inherit from launchd). `ALTERNATE_EDITOR` is the empty string, which tells emacsclient to start the daemon if it is not running. Git commit messages and `crontab -e` open in Emacs.

**One PATH story.** `~/.local/bin` first (on Debian that is where `uv tool`, `npm -g` via `npm_config_prefix`, `pipx` and the `bat`/`fd` shims put their binaries, and `dots` lives there on both OSes), then Homebrew's `bin` on macOS, then the system. Shells get it from `.zshenv`, so scripts, `ssh mac cmd` and Emacs `shell-command` see the same PATH as a terminal. GUI apps get it from the Plasma session env on Linux and from `exec-path-from-shell` on macOS. Emacs additionally prepends `~/.local/bin` to `exec-path` itself, so eglot finds `basedpyright` and `typescript-language-server` even when the daemon was started by systemd or launchd with a minimal environment.

**Keyboard.** Caps Lock and Left Ctrl are swapped on both OSes (KDE `kxkbrc`, macOS `hidutil`), which makes Emacs' `C-` chords comfortable. Key repeat is fast on both. `Meta+E` (KDE) opens an Emacs frame, `Meta+Return` a terminal, `Meta+D` KRunner; `Meta+Arrows` focus the window in that direction, `Meta+Shift+Arrows` tile it to that edge, `Meta+F` maximizes, `Meta+Shift+F` goes fullscreen, `Meta+Shift+Q` closes. On macOS, Option is Meta in Emacs and Ghostty; Command stays Command and the usual `⌘` shortcuts work in Emacs. Window tiling there is macOS' own (Window > Move & Resize, or drag to a screen edge; `Fn+Ctrl+Arrows` by default).

**Package managers own upgrades.** apt installs Emacs, Ghostty, Claude Code, node and the CLI tools on Debian; `uv tool` and `npm -g` add the language servers apt does not carry. Homebrew installs all of it on macOS, as formulas and casks. Emacs `package.el` installs Emacs packages (`package-vc` for the one that is not on an archive). `dots` runs every upgrade. Nothing is curl-piped except Homebrew's installer.

---

## Emacs

### Startup and daemon

`early-init.el` raises the GC threshold and disables `file-name-handler-alist` during startup, then restores sane values. `gcmh` manages GC after startup (collects when idle, not while you type). Frames come up with the stock desktop chrome: menu bar, tool bar, scroll bars, a right-click context menu, a tab bar once there are two tabs, and a row of buffer tabs per window.

The daemon runs under `systemctl --user` (Linux; the unit ships with Debian's `emacs-common`, and if `dots` ran over SSH before your first login it tells you to enable the unit after logging in) or the `com.dotfiles.emacs` LaunchAgent (macOS). Frames connect in about 100 ms; the first time you open a new language, `treesit-auto` asks to compile its grammar, a one-off pause. If the daemon dies, any `emacsclient` call restarts it because `ALTERNATE_EDITOR` is empty.

```sh
systemctl --user status emacs          # Linux
launchctl print gui/$(id -u)/com.dotfiles.emacs   # macOS
emacsclient -e '(kill-emacs)'          # stop the daemon cleanly (either OS)
```

### Packages

Built-in and used: `use-package`, `cua-base`, `eglot`, `treesit`, `which-key`, `editorconfig`, `project`, `flymake`, `ediff`, `repeat-mode`, `pixel-scroll-precision-mode`, `context-menu-mode`, `tab-bar`, `tab-line`, `windmove`, `winner`, `modus-themes`, `savehist`, `recentf`, `save-place`, `dired`, `so-long`, `xterm-mouse-mode`.

Installed from ELPA/MELPA: `gcmh`, `vertico` (with its bundled `vertico-mouse`), `orderless`, `marginalia`, `consult`, `consult-eglot`, `embark`, `embark-consult`, `corfu`, `corfu-terminal`, `cape`, `tempel`, `vundo`, `hl-todo`, `popper`, `treesit-auto`, `apheleia`, `envrc`, `markdown-mode`, `magit`, `diff-hl`, `eat`, `minuet`, `wgrep`, `mood-line`, `ligature`, and on macOS only `exec-path-from-shell`. `claude-code-ide` is not on any archive; `use-package :vc` clones it from GitHub through `package-vc` on first start (`M-x package-vc-upgrade` to update it).

Archives are prioritised GNU > NonGNU > MELPA, so a package available on GNU ELPA never comes from MELPA. `custom.el` (written by Emacs, holds `package-selected-packages`) lives in `~/.config/emacs/`, outside the repo.

### Keys

Stock Emacs keys plus `cua-mode`: with a region active, `C-c` copies, `C-x` cuts, `C-v` pastes, `C-z` undoes (`C-S-z` redoes), and `C-RET` starts a rectangle. `C-x` and `C-c` stay prefixes when the next key follows within 0.2 s, so `C-x C-s` and `C-c g g` work as usual; type `C-c`, pause, and it copies instead. Everything else is Emacs as shipped: `C-x C-f` open, `C-x C-s` save, `C-x b` buffers, `C-x k` kill, `C-x 2` / `C-x 3` / `C-x 0` / `C-x 1` windows, `C-x t 2` new tab and `C-TAB` next tab, `C-x <left>` / `<right>` previous or next buffer, `C-c <left>` / `<right>` undo or redo the window layout (winner), `C-x p …` project commands, `C-x C-j` dired here, `C-x x g` revert, `M-.` / `M-?` definition and references, `M-g i` imenu, `M-y` kill ring, `C-h …` help, `C-h .` documentation at point, `M-;` / `C-x C-;` comment, `<f11>` fullscreen, `C-x C-c` close the frame (the daemon lives on), `M-o` next window. `C-v` and `M-v` belong to cua now; page with `PgUp` / `PgDn`, the wheel or the scroll bar.

`C-c` followed by a letter is the command prefix. Press `C-c` and wait: which-key lists the groups.

| Keys | Action |
|---|---|
| `C-c f r` / `f i` | recent file / open init.el |
| `C-c b s` / `b u` | scratch buffer / undo tree (vundo) |
| `C-c w m` | maximize this window, or bring the layout back on the next press |
| `C-c w <arrows>` | move to the window in that direction; keep pressing arrows to continue |
| `C-c g g` / `g b` / `g l` / `g f` | magit status / blame / log / file dispatch (`C-x g` is status too) |
| `C-c g n` / `g p` / `g r` | next hunk / previous hunk / revert hunk (diff-hl); `n` and `p` repeat |
| `C-c s p` / `s o` / `s m` | ripgrep the project / outline / marks (consult) |
| `C-c l a` / `l r` / `l f` / `l i` / `l s` / `l e` / `l q` | code action / rename / format / implementation / workspace symbols / start eglot / stop eglot |
| `C-c e n` / `e p` / `e l` / `e b` | next error / previous / list (consult) / buffer diagnostics; `n` and `p` repeat |
| `C-c c` | recompile (`C-x p c` compiles the project) |
| `C-c o t` / `o T` | terminal in project root / terminal here |
| `C-c t t` / `t l` / `t w` / `t p` / `t P` | toggle theme / line numbers / word wrap / popup window / cycle popups |
| `C-c a c` / `a a` / `a t` | Claude Code in this project: start / transient menu / show or hide its window |
| `C-c a s` / `a r` / `a C` / `a R` / `a q` | send a prompt / send the region / continue last session / resume a session / stop |

Other bindings: `C-s` consult-line, `C-.` embark-act, `C-;` embark-dwim, `<` narrows a consult list (`C-x b` then `< b` for buffers only, `< f` for files), `TAB` completes or indents, `M-+` inserts a tempel snippet by name (they also show up in the corfu popup). vertico and corfu take `C-n` / `C-p` and the arrow keys. Ghost text from minuet: `TAB` takes all of it, `M-a` one line, `M-e` dismisses, `M-n` / `M-p` cycle, `M-i` asks for a suggestion now ([Claude Code](#claude-code)). Popups (`*Messages*`, `*Warnings*`, help, compilation, flymake lists, plain `eat` terminals) open in a bottom window that `C-c t p` hides and brings back.

In `eat` terminals, including the Claude Code window, cua is off so `C-c` interrupts and `C-v` pastes an image into Claude the way the program expects; copy from a terminal with `M-w` or the right-click menu. The `C-c <letter>` groups still work there.

### Mouse

Click to focus a window (no focus-follows-mouse). Drag selected text within Emacs or into another application; drag files out of dired into a file manager. Right-click anywhere for the context menu (mode-specific entries, plus undo, cut, copy, paste). The wheel scrolls smoothly by pixel, and a tilt or horizontal swipe scrolls long lines sideways. Click a buffer tab to switch, its `×` to close; the tab bar's `+` opens a new workspace. Menus and the tool bar carry the same commands as the keys, so nothing needs memorising to start.

### Languages

`treesit-auto` maps file types to tree-sitter modes and offers to install a grammar the first time you open a language (grammars compile with the system `cc`, which apt and Xcode CLT provide). eglot starts automatically in Python, JavaScript/TypeScript, Rust, Go, C/C++, Bash and Ruby buffers when a server is on PATH. `basedpyright` and `typescript-language-server` are installed by `dots`; for the other languages install the server yourself (`rust-analyzer`, `gopls`, `clangd`, `bash-language-server`, `ruby-lsp`) with apt, `brew`, `uv tool install` or `npm -g` as appropriate, or add it to the lists in `os/` so every machine gets it.

apheleia formats on save with whatever formatter it knows for the mode if that binary is on PATH; missing formatter means no-op, never an error. `ruff`, `prettier` and `shfmt` are installed by `dots`, so Python, JS/TS/JSON/CSS/Markdown and shell format out of the box; `gofmt` and `rustfmt` arrive with their toolchains. envrc loads `.envrc` per buffer so project-local tools win.

### Look

`modus-vivendi` (dark) by default, `C-c t t` toggles to `modus-operandi`. CommitMono Nerd Font 11pt, ligatures for the common operator set, line numbers in code buffers, `mood-line` as a minimal mode-line, no icon packs. On Debian the menu bar, tool bar and scroll bars are GTK widgets and follow the Plasma GTK theme rather than modus, so pick a dark global theme in System Settings if the light chrome bothers you; on macOS they are native and follow the system appearance.

### Terminal frames

`emacsclient -t` (alias `e`) gives a full Emacs inside Ghostty, with a text menu bar (`F10`) and mouse support. Everything works except ligatures and the diff-hl fringe; corfu popups render through `corfu-terminal`. The GUI frame (`emacsclient -c`, alias `eg`) is the daily driver.

---

## Shell

`~/.zshenv` is the only file in `$HOME`; it sets `ZDOTDIR=~/.config/zsh` and sources `~/.config/zsh/.zshenv`. Everything else is in that directory.

- **`.zshenv`** runs for every zsh, including scripts: XDG variables, Homebrew's `bin` and then `~/.local/bin` in front of PATH, `EDITOR`, `PAGER`, `npm_config_prefix=~/.local` (so `npm -g` never needs sudo), npm/python cache locations, cargo env.
- **`.zprofile`** runs for login shells. On macOS, `/etc/zprofile` runs Apple's `path_helper` after `.zshenv` and reorders PATH; `.zprofile` puts Homebrew and `~/.local/bin` back in front. On Linux it only repeats the `~/.local/bin` prepend.
- **`.zshrc`** runs for interactive shells:
  - history: 100k lines, shared between sessions, deduplicated, `HIST_IGNORE_SPACE`;
  - completion: `compinit` with a 24-hour cache, compiled for fast loading, case-insensitive and partial-word matching, fzf-tab drives the menu (`<` `>` switch groups, previews for `cd`, `cp`, `mv`, `rm`, `bat`, `less`, `e`);
  - plugins in the required order: fzf-tab first, autosuggestions (`Ctrl+Space` accepts), syntax-highlighting last;
  - prompt: `➜ dir git:(branch) ✗`, pure `vcs_info`, no async worker, no prompt framework;
  - tool init is cached: `fzf --zsh`, `zoxide init`, `direnv hook` each run once and the output is sourced from `~/.cache/zsh/` until the binary changes; a missing tool is silently skipped;
  - `fd` and `bat` resolve to Debian's `fdfind`/`batcat` automatically.

Keys and widgets:

| Keys | Action |
|---|---|
| `Ctrl+R` / `Ctrl+T` / `Alt+C` | fzf history / file / directory |
| `Alt+Z` | `cdi`: interactive zoxide jump |
| `Ctrl+X Ctrl+P` | `proj`: fuzzy-pick a project under `$DEV_DIR` (`~/dev`, `~/Developer` on macOS), cd, feed zoxide |
| `Ctrl+X Ctrl+G` | live ripgrep across the tree with preview; Enter opens the hit at that line in Emacs |
| `Alt+←` / `Alt+→` / `Alt+B` / `Alt+F` | word motion (all common terminal escape sequences bound) |

Aliases: `ls`/`la` (eza with icons), `e` (`emacsclient -t`), `eg` (`emacsclient -c -n`), `cp`/`rm`/`mkdir` verbose and interactive, `df -h`. `man` pages render through `bat`.

Startup is well under 50 ms because nothing is evaluated at shell start that can be cached.

---

## Terminal: Ghostty

`ghostty/config` is identical on both OSes:

- CommitMono Nerd Font 12pt, Catppuccin Latte/Mocha following the system light/dark setting;
- zsh shell integration (cursor shape, sudo prompt, titles), block cursor, no blink;
- copy on select, no close confirmation, small padding;
- `macos-option-as-alt = true` so Option sends Meta to Emacs in terminal frames;
- splits and tabs on `Ctrl+Shift`: `T` tab, `N` window, `W` close, `Enter` split right, `Backspace` split down, `Arrows` move between splits, `F` fullscreen.

Linux gets Ghostty from the `mkasberg/ghostty-ubuntu` release builds, which publish `.deb` files for Debian codenames; `os/linux.sh` pins the version and the SHA-256 of the trixie `amd64` and `arm64` packages, downloads the one matching your architecture, and refuses to install on a checksum mismatch. `dots` compares the installed package version with the pin, so bumping `GHOSTTY_TAG` upgrades every machine on its next sync. If there is no pinned build for your codename, Konsole stays and `kde/apply.sh` binds `Meta+Return` to it instead. macOS gets the official cask.

---

## Git

`config/git/config` sets: delta as pager with line numbers, `zdiff3` conflict style, histogram diff, `rerere`, autostash on rebase, prune on fetch, `push.autoSetupRemote`, branch list sorted by recent commit, verbose commit messages, `main` as the default branch, and a handful of aliases (`st`, `cm`, `co`, `br`, `last`, `unstage`, `hist`).

Identity, credential helpers and signing are not set here; git reads `~/.gitconfig` after this file, so whatever the machine already has wins. `~/.config/git/config.local` is included last and never committed, for overrides you want beside the repo config instead. To sign commits with your SSH key from there:

```ini
[user]
	signingkey = ~/.ssh/id_ed25519.pub
[commit]
	gpgsign = true
[gpg]
	format = ssh
```

Register the same public key on GitHub as a signing key for "Verified" badges.

`core.editor` is not set; git follows `VISUAL`/`EDITOR`, so it opens a terminal frame in shells and a GUI frame from GUI apps.

---

## Toolchains

No version manager. Each tool comes from the package manager that has it, and `dots` upgrades all of them:

| Tool | Debian | macOS |
|---|---|---|
| `node`, `npm` | apt (`nodejs` 20, the Debian 13 release) | `brew "node"` (current) |
| `uv` | `pipx install uv` (apt has `pipx`, not `uv`) | `brew "uv"` |
| `ruff`, `basedpyright` | `uv tool install`, from `os/uv-tools.txt` | Homebrew formulas |
| `typescript`, `typescript-language-server`, `prettier` | `npm install -g`, from `os/npm-packages.txt` | Homebrew formulas |
| `shfmt`, `jq`, `fzf`, `eza`, `zoxide`, `ripgrep`, `fd`, `bat`, `delta`, `direnv`, `shellcheck` | apt | Homebrew formulas |

On Debian everything user-installed lands under `~/.local` (`npm_config_prefix` is set in `.zshenv` and by `os/linux.sh`), so nothing needs sudo and nothing fights apt. Per-project versions are the project's business (`.envrc`, a virtualenv, `npx`); nothing global changes per directory.

To add a tool for every machine: apt name into `os/apt-packages.txt`, formula into `os/Brewfile`, and for Debian-only gaps a line in `os/uv-tools.txt` or `os/npm-packages.txt`; then `dots`.

---

## KDE

`kde/apply.sh` writes only the keys this repo owns, via `kwriteconfig6`, and leaves the rest of Plasma's config alone:

- `kxkbrc`: `ctrl:swapcaps`;
- `kcminputrc`: repeat delay 250 ms, rate 40/s;
- `kdeglobals`: fixed-width font CommitMono Nerd Font 11;
- `kglobalshortcutsrc`: `Meta+E` Emacs frame, `Meta+Return` terminal, `Meta+D` KRunner, `Meta+Shift+Q` close window, `Meta+Arrows` focus the window in that direction, `Meta+Shift+Arrows` quick-tile it there (Plasma's default `Meta+Shift+Left/Right`, move to the previous or next screen, is unset so the tile keys win), `Meta+F` maximize, `Meta+Shift+F` fullscreen.

Plasma 6 removed the "Custom Shortcuts" module; launching a command from a shortcut requires a `.desktop` file (`kde/dotfiles-emacs.desktop`, hidden from menus) and a `kglobalshortcutsrc` entry under `[services]` keyed by the file name with a bare key sequence as the value. `kglobalaccel` does not reliably reload; the script restarts it, and a logout applies everything for certain. `dots` runs the script on the first sync and whenever `kde/` changes, when it is inside a Plasma session; otherwise it tells you to run it after login.

`kde/env.sh` is sourced by `startplasma` for the whole session, so every GUI app sees `~/.local/bin` on PATH and `EDITOR=emacsclient -c`.

`emacs-pgtk` is the Emacs build: native Wayland with correct fractional scaling, and it runs on X11 too.

---

## macOS specifics

- **Homebrew** lives in `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel); `.zshenv` detects which, so non-login shells and Emacs see it too. `HOMEBREW_NO_ANALYTICS=1` is set globally. CLI tools and language servers are formulas; the login shell stays `/bin/zsh` (Homebrew's `zsh` is not installed).
- **Emacs** is the `emacs-app` cask from [jimeh/emacs-builds](https://github.com/jimeh/emacs-builds): a signed, notarized `/Applications/Emacs.app` with native compilation, currently Emacs 31, for macOS 11 and later on both architectures. No source build, so `brew upgrade` is a download. The cask links `emacs` and `emacsclient` into Homebrew's `bin`. The daemon is the `com.dotfiles.emacs` LaunchAgent running `Emacs --fg-daemon` with `KeepAlive`, so it comes back if it dies.
- **Modifiers in Emacs**: left Option is Meta, right Option is left alone for special characters, Command is Super. `⌘C` / `⌘V` / `⌘X` / `⌘Z` / `⌘S` / `⌘A` / `⌘W` work (Emacs' own ns bindings), `⌘⇧Z` redoes, and `⌘Q` closes the frame instead of killing the daemon.
- **Caps Lock ↔ Left Ctrl** uses `hidutil` in a LaunchAgent (`com.dotfiles.capslock`), re-applied at each login because the mapping does not persist across reboots.
- **`defaults`** applied by `os/macos/defaults.sh`; edit the list before running if you disagree with any. Dock and Finder restart automatically; keyboard settings apply after logout. `dots` re-applies it only when the file changed.
- **SSH** uses the Keychain for the key passphrase (`UseKeychain yes`).
- **Window tiling** is macOS' own: drag a window to an edge, use Window > Move & Resize, or `Fn+Ctrl+Arrows`. No third-party tiler.
- **Claude Code** is the `claude-code` Homebrew cask. It and Ghostty update themselves, which is why plain `brew upgrade` skips them; `brew upgrade --greedy` forces a Homebrew-side update.

---

## Claude Code

One posture: Claude reads, researches, debugs, reviews and plans. You write the code. The point is to keep the understanding that comes from typing it, and to have a session that knows the codebase and the goal sitting next to the buffer while you do.

### What Claude can and cannot do

- **No edits, ever.** `settings.json` denies `Edit`, `MultiEdit`, `Write` and `NotebookEdit`. A deny rule holds under every permission mode and every command-line flag; the only way to get an agent editing files is to change `settings.json`. Nothing on disk comes from a session except Claude Code's own transcripts under `~/.claude/projects`.
- **Read-only shell without prompts.** `rg`, `cat`, `head`, `tail`, `ls`, `wc`, `cut`, `jq`, `diff`, `stat`, `file`, `which`, `uv tool list`, `npm ls` and the read-only git subcommands are allowed; file finding goes through Claude's own Glob and Grep tools, which never prompt. Tools that can write or execute through a flag (`fd -x`, `tree -o`, `sort -o`) are deliberately not on the list. A shell redirection (`cat x > y`) is checked against the file rules as a write, so the `Write` deny catches it. Anything that mutates, including running your tests or a server, prompts once; `git push` is denied. Answer a prompt with "yes", not "always": "always" writes `.claude/settings.local.json` into the project (globally gitignored, but still a file).
- **No sandbox.** Commands run on the machine as you.
- **Read anywhere.** `Read(~/**)` and `/tmp`, so it can look at other repos, logs and dotfiles when the question needs it.
- `claude/CLAUDE.md` says the rest. A question gets the approach, the tradeoffs and the `file:line` involved. "Walk me through it" gets one step at a time (`file:line`, what to write, why), then Claude waits for "next" and reads your buffer before the next step, so the steps track what you actually typed.
- `/investigate <ticket | PR | path | topic>` builds a read-only brief (ticket, PR threads, code map with `file:line`, prior art, open questions) and stops. `/review <PR#>` runs the adversarial review lenses over a PR and drafts comments in your voice; you post them. Both assume a ticket tracker or code host reachable over MCP for the fetching parts and fall back to asking you to paste.

### Inside Emacs

`claude-code-ide.el` runs the real Claude Code TUI in an `eat` window, so every plugin, skill and the statusline work unchanged, and it registers Emacs as Claude's IDE over MCP: Claude sees the current buffer and selection and can read flymake diagnostics, xref, imenu and project info. `C-c a c` starts it for the current project, `C-c a r` sends the region into the prompt, `C-c a s` sends a typed prompt, `C-c a t` hides and shows the window, `C-c a C` / `a R` continue or resume a session, `C-c a a` opens the transient menu with everything else. Outside Emacs, `claude` in Ghostty is the same thing minus the buffer awareness.

### Completion: minuet

`minuet` puts multi-line ghost text under the cursor, from Gemini Flash-Lite routed through OpenRouter: a chat model, chosen because the "stay silent unless certain" rule below is an instruction, and pure fill-in-the-middle endpoints (Codestral, a local Ollama) cannot take one. OpenRouter because it is one prepaid key for any model and no Google Cloud billing to fight; at Flash-Lite prices a day of typing costs a few cents. Another model is one string in `init.el` (`:model` in `minuet-openai-compatible-options`); another provider is `minuet-provider` plus its options plist, and minuet also speaks Gemini, OpenAI, Codestral, DeepSeek, Ollama and the Anthropic API directly. It is built to stay out of the way:

- It only fires right after you typed or deleted something (a click or an arrow key never triggers it), at the end of a line (closing brackets and quotes that electric-pair put there do not count), when corfu's popup is not up, at most every 1.5 seconds. LSP completion always has right of way; minuet gets the quiet spots, after a `(`, a `=`, a `:` or a newline.
- The prompt tells the model to return nothing unless the surrounding code and the conversation make the next code certain. No overlay appears for an empty answer, so a bad guess costs nothing but the request.
- One candidate, never a menu. `TAB` accepts the whole block while it is showing (TAB is back to indent/complete the moment it is gone); `M-a` accepts a line, and that is the habit worth keeping; `M-e` dismisses; typing on dismisses too. `M-i` asks for a suggestion on demand in any code buffer. Requests get five seconds before they are dropped.
- The bridge to the session: when a Claude window is open for the project, the last 60 lines of it go into the completion prompt, so what you and Claude just agreed on shapes the suggestion. No file is written anywhere for this. If it turns out noisy, drop `dot/minuet-chat-tail` from `dot/minuet-prompt` in `init.el`.
- Too chatty overall: remove the `prog-mode` hook and keep `M-i`. That is on-demand mode, and some people prefer it.

The API key comes from `auth-source`: the first `M-i` asks for it and offers to save it to `~/.authinfo`, or you put it in `~/.authinfo.gpg` yourself (see [After bootstrap](#after-bootstrap)). Without a key, auto-suggestion is blocked and nothing else changes.

### The rest of `settings.json`

- **Plugins**: `typescript-lsp`, `pyright-lsp` (diagnostics for Claude's reading), `caveman` (terse answers; from a third-party marketplace, `JuliusBrussee/caveman`; drop both entries if you do not want it). Install them once with the `jq | xargs` one-liner in [After bootstrap](#after-bootstrap).
- **Statusline**: `claude/statusline.sh` shows exceptions only: model, `project:branch`, effort when it is not `high`, context usage with a hand-off warning at 25 %, and the 5h/7d rate-limit windows once they pass 50 %. One `jq` call, plus `git` for the branch.
- **Not managed**: `~/.claude/hooks` and `settings.local.json` are yours; `dots` never touches them.

---

## Upgrading: dots

`dots` is the one command. Run it on any machine after pushing changes from another, or just to upgrade:

- `git pull --ff-only` in the repo (a failure, offline or diverged, is reported and the run continues with the local tree) and `git submodule update`;
- re-links every file (`dots link` alone does just this; `dots check` verifies every link);
- `os/linux.sh`: `apt-get update` + install + `upgrade`, `pipx upgrade-all`, `uv tool upgrade --all`, `npm install -g` of the list (which upgrades), the Ghostty pin, the daemon unit, Claude Code; or `os/macos.sh`: `brew update`, `brew bundle`, `brew upgrade`, `brew autoremove`, `brew cleanup`, the LaunchAgents;
- restarts the Emacs daemon if `emacs/` changed since the last run (close your Emacs frames first, unsaved buffers do not survive);
- re-runs `kde/apply.sh` (inside Plasma) or `os/macos/defaults.sh` if those changed;
- prints the manual tail: new terminal, log out and in, `dots check`.

Every step checks before it acts, so re-running is always safe. What `dots` does not do:

| What | Command |
|---|---|
| Emacs packages | `M-x package-upgrade-all`, then `M-x package-autoremove`; `M-x package-vc-upgrade` for `claude-code-ide` |
| zsh plugins | `git -C ~/dev/dotfiles submodule update --remote`, commit, push, `dots` elsewhere |
| Ghostty on Linux | bump `GHOSTTY_TAG` and the `GHOSTTY_SHA256_*` values in `os/linux.sh`, push, `dots` |
| Self-updating casks on macOS (Ghostty, Claude Code) | they update themselves; `brew upgrade --greedy` forces it |

---

## Verification and CI

`.github/workflows/ci.yml` runs on every push:

- **Linux job** in a `debian:trixie` container (the exact target): installs every package in `os/apt-packages.txt` (a wrong name fails here, not on your new box), installs every entry of `os/uv-tools.txt` and `os/npm-packages.txt` into a throwaway `HOME` and checks each binary landed in `~/.local/bin`, `shellcheck` on every script including `bin/dots`, `zsh -n` on every zsh file, `jq` on `settings.json`, `git config` parse, then `dots link` twice into a fresh `HOME` with a file in the way (the `moved` path, then the stale-link path), `dots check`, `~/.local/bin/dots` executable, an interactive zsh start that must print nothing, and finally Emacs 30 loads `early-init.el` + `init.el` in batch mode, installing every package from the real archives and cloning `claude-code-ide` (ELPA cache keyed on `init.el`), and byte-compiles both files.
- **macOS job**: `brew bundle` against the real `os/Brewfile` with the casks skipped, so every tap, formula and cask name resolves and the formulas install for real; then shellcheck, `zsh -n`, `plutil -lint` on both LaunchAgents, the same double `dots link` and `dots check`, interactive zsh start, and the same Emacs batch load and byte-compile with Homebrew's `emacs` formula, so the `darwin` branch of `init.el` runs for real.

Not covered: `bootstrap.sh` end to end (needs a GitHub login), `os/linux.sh`, `os/macos.sh`, `kde/apply.sh`, and anything that needs a display.

Locally: `dots check` after anything that might have replaced a symlink.

---

## Forking

1. Fork on GitHub, then in `bootstrap.sh` change `REPO_URL`, or run it with `DOTFILES_REPO=git@github.com:you/dotfiles`.
2. Edit `os/apt-packages.txt`, `os/Brewfile`, `os/uv-tools.txt` and `os/npm-packages.txt` to taste.
3. Adjust `kde/apply.sh` and `os/macos/defaults.sh`; both are lists of individual settings, remove lines you do not want.
4. `claude/settings.json`: change or drop `model` (it names a specific tier), the plugins (`caveman` and its `extraKnownMarketplaces` entry point at a third-party GitHub repo), and `Read(~/**)` if you want Claude confined to your working directories. Remove the `Edit`/`Write` denies if you want an agent that edits; nothing else in the repo assumes it cannot.
5. `claude/skills/review` assumes a code host reachable over MCP or comments pasted by hand; `/investigate` works on a bare path. Delete what you do not use. `minuet` in `init.el` needs an OpenRouter API key; without one it does nothing.
6. Nothing else references a person: git identity and SSH keys are whatever the machine already has; bootstrap only checks they exist.

---

## Troubleshooting

**Shell looks wrong / plugins missing.** `~/.zshenv` must be a symlink into the repo. `dots check` reports it as `DRIFT`. Run `dots link`.

**`dots` says the pull failed.** Offline, or the clone has diverged from origin. It carried on with the local tree; reconcile with `git -C ~/dev/dotfiles pull --rebase` and run `dots` again.

**`compinit: insecure directories` on macOS.** `os/macos.sh` fixes permissions; re-run it, or `compaudit | xargs chmod g-w,o-w`.

**`emacsclient: can't find socket`.** The daemon is not running and `ALTERNATE_EDITOR` is not empty in this environment. `systemctl --user restart emacs` (Linux) or `launchctl kickstart -k gui/$(id -u)/com.dotfiles.emacs` (macOS), or just `emacsclient -a '' -c`. If `dots` ran over SSH before your first graphical login, the unit was never enabled: `systemctl --user enable --now emacs.service`.

**Emacs ignores the repo config.** A `~/.emacs`, `~/.emacs.el` or `~/.emacs.d` exists; Emacs loads that and never looks at `~/.config/emacs`. Move it aside.

**Claude in Emacs: "claude not found" or it cannot see the buffer.** The daemon's PATH must contain `claude` (`emacsclient -e '(executable-find "claude")'`). On macOS `exec-path-from-shell` copies it from a login shell; on Linux it is `/usr/bin/claude` from apt. No buffer awareness means the Claude session was started outside Emacs; start it with `C-c a c` so it connects over MCP.

**minuet shows nothing.** No key yet means no auto-suggestions; `M-i` asks for the key. Otherwise check `*minuet*` (the log buffer). A 402 in the log means the OpenRouter credit ran out. Otherwise it is working as designed: the model returned nothing because it was not sure. `M-i` forces a request.

**Emacs starts but packages are missing.** First launch needs network to ELPA/MELPA. `M-x package-refresh-contents`, then `M-x package-install-selected-packages`. Corporate proxies: set `url-proxy-services` in `custom.el`.

**eglot: "no server".** Either the server was never installed (only `basedpyright` and `typescript-language-server` ship by default; see [Languages](#languages) for the rest) or it is not on the daemon's PATH. `uv tool list` and `npm ls -g` (Debian) or `brew list` (macOS) show what is installed; `emacsclient -e '(getenv "PATH")'` shows what the daemon sees. Restart the daemon after installing a new tool.

**Fonts look wrong in Emacs.** `fc-list | grep -i commitmono` (Linux) or Font Book (macOS) must list "CommitMono Nerd Font". Re-run `os/linux.sh` / `brew install --cask font-commit-mono-nerd-font`.

**KDE shortcut does nothing.** Log out and in; `kglobalaccel` does not always pick up file changes. Check `~/.local/share/applications/dotfiles-emacs.desktop` exists.

**Ghostty not installed on Linux.** No community build for your Debian codename. Check <https://github.com/mkasberg/ghostty-ubuntu/releases>, bump `GHOSTTY_TAG` and the `GHOSTTY_SHA256_*` values in `os/linux.sh` (the release API lists each asset's `digest`), or build from source. Konsole is bound to `Meta+Return` meanwhile.

**macOS: Caps Lock is still Caps Lock.** `launchctl list | grep capslock` should show the agent; `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.dotfiles.capslock.plist` loads it. Some keyboards need the remap re-applied after sleep; the agent runs at login only.
