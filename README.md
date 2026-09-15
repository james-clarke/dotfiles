# dotfiles

A lean, keyboard-driven development environment for **Debian 13 + KDE Plasma 6** and **macOS**, built around **Emacs 30** (evil, vertico, eglot), a framework-free **zsh**, **Ghostty**, **mise**, git, and **Claude Code** running inside Emacs as a read-only partner: it investigates, plans and walks you through, you type, `minuet` completes. One command bootstraps a fresh machine on either OS, and asks before touching anything an existing machine already has; every file is symlinked from this repo so edits are versioned; CI proves the shell and the Emacs config load cleanly on both platforms.

Nothing here is tied to a person or an employer. Fork it, change one URL, and it is yours.

---

## Contents

1. [What you get](#what-you-get)
2. [Install: Debian 13 + KDE](#install-debian-13--kde)
3. [Install: macOS](#install-macos)
4. [Existing machine](#existing-machine)
5. [After bootstrap](#after-bootstrap)
6. [Repository layout](#repository-layout)
7. [How the pieces fit](#how-the-pieces-fit)
8. [Emacs](#emacs)
9. [Shell](#shell)
10. [Terminal: Ghostty](#terminal-ghostty)
11. [Git](#git)
12. [Toolchains: mise](#toolchains-mise)
13. [KDE](#kde)
14. [macOS specifics](#macos-specifics)
15. [Claude Code](#claude-code)
16. [Upgrading](#upgrading)
17. [Verification and CI](#verification-and-ci)
18. [Forking](#forking)
19. [Troubleshooting](#troubleshooting)

---

## What you get

| Area | Choice | Why |
|---|---|---|
| Editor | Emacs 30, running as a daemon, `emacsclient` frames | Instant frames, one process, same config on both OSes |
| Keys | evil (vim keys) + `SPC` leader | Modal editing with a discoverable leader menu (which-key) |
| Completion | vertico, orderless, marginalia, consult, embark, corfu, cape | The current lean consensus stack; all small, all pure elisp |
| LSP | eglot (built-in) + treesit (built-in) | No lsp-mode, no UI sprawl; servers come from mise |
| Git in Emacs | magit, diff-hl | The reason to use Emacs |
| Formatting | apheleia | Async format-on-save, cursor stays put |
| Terminal in Emacs | eat | Pure elisp, no C module to compile |
| Shell | zsh, no framework | `~/.zshenv` stub + `~/.config/zsh/`; plugins as git submodules; cached tool init |
| Terminal | Ghostty | One config file for KDE and macOS; GPU fast; Meta passes through cleanly |
| Toolchains | mise | node, uv, LSP servers; one global config, per-project overrides |
| Git | delta pager, sane defaults | Identity, keys and signing stay whatever the machine already has |
| Fonts | CommitMono Nerd Font | Ligatures + icons, installed by bootstrap |
| AI | Claude Code CLI, `claude-code-ide.el`, `minuet` | Claude runs inside Emacs (`SPC a c`), sees your buffer and diagnostics, and cannot edit files: it investigates, plans and walks you through; you type. minuet gives ghost-text completion that reads the Claude window for context |
| Package managers | apt / Homebrew for everything with a package | Upgrades ride `apt upgrade` / `brew upgrade` |

Package counts stay small on purpose. Emacs pulls two dozen packages (plus their dependencies) from GNU ELPA, NonGNU ELPA and MELPA through the built-in `package.el`. There is no elpaca, straight, doom, or spacemacs layer.

---

## Install: Debian 13 + KDE

1. Install Debian 13 from the netinst with **KDE Plasma** and **standard system utilities**. Log in once so Plasma creates its config directories. A Wayland session is recommended (the default); the bootstrap picks the matching Emacs build.

2. Set up git the way you normally would: `sudo apt install git`, `git config --global user.name` / `user.email`, and an SSH key registered on GitHub ([guide](https://docs.github.com/authentication/connecting-to-github-with-ssh)). `ssh -T git@github.com` must answer "successfully authenticated". The bootstrap checks all three and stops with the same instructions if any is missing; it never creates keys or touches `~/.gitconfig`.

3. Run the bootstrap. It is idempotent; re-run it whenever you like.
   ```sh
   curl -fsSL https://raw.githubusercontent.com/james-clarke/dotfiles/master/bootstrap.sh | bash
   ```
   What it does, in order:
   - Checks git, your identity and SSH access to GitHub, then `apt install curl` if needed.
   - Clones this repo over SSH with submodules to `~/dev/dotfiles` (override with `DOTFILES_DIR`); on a re-run it pulls instead.
   - Runs `preflight.sh`: on a machine that already has shell files, an Emacs config or a Claude Code setup, asks what to keep ([Existing machine](#existing-machine)). A fresh box sails through.
   - Runs `install.sh`: symlinks every config file into place, moving anything that already exists into `~/.local/state/dotfiles/archive/<timestamp>/`, and removes links from earlier runs whose entry has since left the table (recorded in `~/.local/state/dotfiles/links`).
   - Runs `os/linux.sh`:
     - installs everything in `os/apt-packages.txt`;
     - installs `emacs-pgtk` on a Wayland session, `emacs-gtk` on X11;
     - installs mise from its apt repository (enabled through Debian's `extrepo`, which carries the signing key);
     - downloads CommitMono Nerd Font into `~/.local/share/fonts` and refreshes the font cache;
     - installs Ghostty from the community `.deb` build (pinned version) or leaves Konsole in place if no build exists for your Debian codename;
     - enables the Emacs daemon as a systemd user service;
     - adds the Claude Code apt repository (GPG fingerprint verified) and installs `claude-code`;
     - runs `kde/apply.sh` if you are inside a Plasma session;
     - sets zsh as the login shell.
   - Runs `mise install` for the global toolchain.

4. Log out and back in. This activates the zsh login shell, the Plasma session environment (`EDITOR`, `PATH` with mise shims), the keyboard remap and the global shortcuts.

5. Continue at [After bootstrap](#after-bootstrap).

---

## Install: macOS

1. Have git set up: `xcode-select --install` provides it, then `git config --global user.name` / `user.email` and an SSH key registered on GitHub ([guide](https://docs.github.com/authentication/connecting-to-github-with-ssh)). `ssh -T git@github.com` must answer "successfully authenticated". The bootstrap checks and stops otherwise; it never creates keys or touches `~/.gitconfig`.

2. Run the bootstrap.
   ```sh
   curl -fsSL https://raw.githubusercontent.com/james-clarke/dotfiles/master/bootstrap.sh | bash
   ```
   What it does, in order:
   - Checks git, your identity and SSH access to GitHub.
   - Installs Xcode Command Line Tools if missing (the script exits and asks you to re-run once the installer finishes).
   - Installs Homebrew if missing.
   - Clones the repo over SSH with submodules to `~/dev/dotfiles`.
   - Runs `preflight.sh` ([Existing machine](#existing-machine)): an Emacs you already have and a `~/.claude` setup are detected and you choose what happens to each; an existing `~/.gitconfig` is noted and left alone.
   - Runs `install.sh` (symlinks, archive of anything in the way, stale-link pruning).
   - Runs `os/macos.sh`:
     - `brew bundle` against `os/Brewfile`: `emacs-plus@30` (native-comp, a source build), Ghostty, Claude Code, the Nerd Font;
     - installs `mise` as a prebuilt binary into `~/.local/bin` (its Homebrew formula compiles Rust on any macOS without bottles); the CLI tools (`jq`, `fzf`, `eza`, `zoxide`, `ripgrep`, `fd`, `bat`, `delta`, `direnv`, `shellcheck`) come through mise from `config/mise/conf.d/macos.toml`, so a macOS release Homebrew no longer bottles for still installs in a minute;
     - copies `Emacs.app` to `/Applications` so Spotlight and the Dock can launch it;
     - starts the Emacs daemon via `brew services` (a launchd agent); both Emacs steps are skipped if preflight kept an Emacs you already had;
     - makes `/bin/zsh` the login shell if it is not;
     - installs a LaunchAgent that swaps Caps Lock and Left Ctrl at every login (`hidutil`);
     - applies a curated set of `defaults write` (fast key repeat, no press-and-hold accents, no smart quotes, Finder shows extensions and hidden files, Dock autohide);
     - adds `AddKeysToAgent` / `UseKeychain` to `~/.ssh/config`;
     - fixes the Homebrew completion-directory permissions that otherwise trigger `compinit` warnings.
   - `mise install`.

3. Log out and back in (or reboot) so the keyboard remap, key repeat and login shell environment apply everywhere.

4. Continue at [After bootstrap](#after-bootstrap).

---

## Existing machine

`preflight.sh` runs inside `bootstrap.sh` (and stands alone: `~/dev/dotfiles/preflight.sh`). It looks at what the machine already has and asks one question per item; Enter takes the suggested answer. Without a terminal (CI, a truly blind `curl | bash`) it keeps everything and says so. Answers are saved in `~/.local/state/dotfiles/preflight`; delete a line to be asked again. Anything archived lands in `~/.local/state/dotfiles/archive/<timestamp>/` under its original relative path, so restoring is a `mv` back.

| It finds | Choices | Notes |
|---|---|---|
| `~/.zshrc`, `~/.zprofile`, `~/.zlogin`, `~/.oh-my-zsh` | archive (suggested) / keep | zsh reads only `~/.zshenv` from `$HOME` once `ZDOTDIR` is set; kept files are dead weight |
| `~/.zshenv` | not asked | the one file the repo must own (it sets `ZDOTDIR`); `install.sh` archives yours and links its own |
| `~/.bashrc`, `~/.bash_profile` | keep (suggested) / archive | bash still uses them |
| `~/.emacs`, `~/.emacs.el`, `~/.emacs.d` | archive (suggested) / keep | Emacs prefers these and ignores `~/.config/emacs` while they exist; keep means the repo config does not load |
| An Emacs already installed (macOS: `/Applications/Emacs.app`, `brew` formula or cask) | keep (suggested) / replace | keep skips `emacs-plus@30` and the `brew services` daemon; you run `emacs --daemon` your way, and preflight warns if no `emacsclient` is on PATH. replace makes `os/macos.sh` uninstall a `brew` `emacs` formula, archive a foreign `/Applications/Emacs.app` and install `emacs-plus@30` |
| `~/.gitconfig` | report only | git reads it after `~/.config/git/config`, so its identity, signing and helper settings override the repo defaults. Never touched |
| `~/.claude/{CLAUDE.md,settings.json,statusline.sh,skills}` that are not repo links | keep (suggested) / replace | keep makes `install.sh` skip the whole `claude` group (`DOTFILES_SKIP=claude` does the same by hand). If your `settings.json` has a `hooks` block it says so; the repo copy has none |
| `~/.nvm`, `~/.pyenv`, `~/.rbenv`, `~/.asdf` | report only | mise covers them; remove when ready |

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
   ~/dev/dotfiles/install.sh check
   ```

5. Open Emacs: `Meta+E` on KDE, Spotlight → "Emacs" on macOS, or `e file` in any terminal. The first launch installs the Emacs packages, including a `git clone` of `claude-code-ide.el` (one to two minutes, once). Native compilation runs in the background afterwards; ignore the `*Async-native-compile-log*` buffer.

6. Linux only, if bootstrap ran outside a Plasma session: run `~/dev/dotfiles/kde/apply.sh` now, then log out and in.

---

## Repository layout

```
bootstrap.sh            one-shot installer; OS-independent steps, dispatches to os/
preflight.sh            existing machine: inventory, ask keep/archive/replace per item, remember answers
install.sh              symlinks repo files into $HOME; `install.sh check` verifies; DOTFILES_SKIP skips groups
os/
  linux.sh              Debian 13 + KDE packages, Emacs daemon, Ghostty, Claude Code, fonts
  macos.sh              Homebrew bundle, Emacs daemon, keyboard remap, defaults
  apt-packages.txt      flat apt list
  Brewfile              formulae, taps, casks
  macos/defaults.sh     curated `defaults write`
  macos/capslock.plist  LaunchAgent: Caps Lock <-> Left Ctrl
emacs/
  early-init.el         GC and frame settings applied before the GUI exists
  init.el               the whole Emacs config, one file
  templates             tempel snippets, a handful per mode
zsh/
  home.zshenv           the only file in $HOME; sets ZDOTDIR and sources the real .zshenv
  .zshenv               env for every zsh: XDG dirs, PATH, EDITOR
  .zprofile             login shells: Homebrew PATH order on macOS
  .zshrc                interactive: history, completion, prompt, plugins, tools, widgets
  plugins/              fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting (submodules)
ghostty/config          shared terminal config
config/
  git/config            git defaults; includes config.local for machine-specific overrides
  git/ignore            global gitignore
  mise/config.toml      global toolchain
  mise/conf.d/macos.toml CLI tools on macOS (apt provides them on Linux)
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
| `zsh/home.zshenv` | `~/.zshenv` |
| `zsh/` | `~/.config/zsh/` |
| `emacs/early-init.el`, `emacs/init.el`, `emacs/templates` | `~/.config/emacs/` (packages, `custom.el`, `eln-cache` live there too, untracked) |
| `ghostty/config` | `~/.config/ghostty/config` |
| `config/git/*` | `~/.config/git/` |
| `config/mise/config.toml` | `~/.config/mise/config.toml` |
| `config/mise/conf.d/macos.toml` | `~/.config/mise/conf.d/macos.toml` (macOS only) |
| `claude/*` | `~/.claude/` |
| `kde/env.sh` (Linux) | `~/.config/plasma-workspace/env/dotfiles.sh` |
| `kde/dotfiles-emacs.desktop` (Linux) | `~/.local/share/applications/` |

Files that must not be symlinks (Plasma rewrites its rc files atomically, launchd wants a real plist) are written by `kde/apply.sh` and `os/macos.sh` instead.

---

## How the pieces fit

**Editor everywhere.** `EDITOR` and `VISUAL` are `emacsclient -t` in shells (a terminal frame inside your current terminal, fast, closes with `C-x #` or `:q`), and `emacsclient -c` for GUI sessions (KDE via `kde/env.sh`; macOS apps inherit from launchd). `ALTERNATE_EDITOR` is the empty string, which tells emacsclient to start the daemon if it is not running. Git commit messages and `crontab -e` open in Emacs.

**One PATH story.** `~/.local/bin` first, then mise shims, then the system. Shells get it from `.zshenv`/`.zprofile`. GUI apps get it from the Plasma session env on Linux and from `exec-path-from-shell` on macOS. Emacs additionally prepends both directories to `exec-path` itself, so eglot finds `basedpyright` and `typescript-language-server` even when the daemon was started by systemd or launchd with a minimal environment.

**Keyboard.** Caps Lock and Left Ctrl are swapped on both OSes (KDE `kxkbrc`, macOS `hidutil`); Escape in evil is `C-[`. Key repeat is fast on both. `Meta+E` (KDE) opens an Emacs frame, `Meta+Return` a terminal, `Meta+D` KRunner. On macOS, Option is Meta in Emacs and Ghostty; Command stays Command.

**Package managers own upgrades.** apt installs Emacs, Ghostty, Claude Code, mise and the CLI tools on Linux. Homebrew installs Emacs, Ghostty, Claude Code and the font on macOS; the CLI tools there come from mise as prebuilt binaries, because Homebrew stops bottling formulae for a macOS release after about three years and everything would compile from source. mise installs language toolchains, LSP servers and formatters on both. Emacs `package.el` installs Emacs packages (`package-vc` for the one that is not on an archive). Nothing is curl-piped except Homebrew's and mise's installers on macOS.

---

## Emacs

### Startup and daemon

`early-init.el` raises the GC threshold and disables `file-name-handler-alist` during startup, then restores sane values; it also turns off the menu bar, tool bar and scroll bars before the first frame exists. `gcmh` manages GC after startup (collects when idle, not while you type).

The daemon runs under `systemctl --user` (Linux; the unit ships with Debian's `emacs-common`, and if bootstrap ran over SSH before your first login it tells you to enable the unit after logging in) or `brew services` (macOS). Frames connect in about 100 ms; the first time you open a new language, `treesit-auto` asks to compile its grammar, a one-off pause. If the daemon dies, any `emacsclient` call restarts it because `ALTERNATE_EDITOR` is empty.

```sh
systemctl --user status emacs          # Linux
brew services info emacs-plus@30       # macOS
emacsclient -e '(kill-emacs)'          # stop the daemon cleanly (either OS)
```

### Packages

Built-in and used: `use-package`, `eglot`, `treesit`, `which-key`, `editorconfig`, `project`, `flymake`, `ediff`, `repeat-mode`, `pixel-scroll-precision-mode`, `modus-themes`, `savehist`, `recentf`, `save-place`, `winner`, `dired`, `so-long`, `xterm-mouse-mode`.

Installed from ELPA/MELPA: `gcmh`, `evil`, `evil-collection`, `evil-surround`, `vertico`, `orderless`, `marginalia`, `consult`, `consult-eglot`, `embark`, `embark-consult`, `corfu`, `corfu-terminal`, `cape`, `tempel`, `vundo`, `hl-todo`, `popper`, `treesit-auto`, `apheleia`, `envrc`, `markdown-mode`, `magit`, `diff-hl`, `eat`, `minuet`, `wgrep`, `mood-line`, `ligature`, and on macOS only `exec-path-from-shell`. `claude-code-ide` is not on any archive; `use-package :vc` clones it from GitHub through `package-vc` on first start (`M-x package-vc-upgrade` to update it).

Archives are prioritised GNU > NonGNU > MELPA, so a package available on GNU ELPA never comes from MELPA. `custom.el` (written by Emacs, holds `package-selected-packages`) lives in `~/.config/emacs/`, outside the repo.

### Keys

evil is vim. `C-u` scrolls up, `Y` yanks to end of line, undo is the built-in `undo-redo`, search is `evil-search` (vim-style regexps), `K` shows eldoc for the symbol at point, `gcc` / `gc` comment lines and regions. `evil-collection` gives vim keys to magit, dired, help, compilation, eat, and everything else.

`SPC` is the leader in normal and visual state. Press it and wait: which-key lists the groups.

| Keys | Action |
|---|---|
| `SPC SPC` | M-x |
| `SPC ,` | switch buffer (consult) |
| `SPC .` | find file |
| `SPC /` | ripgrep the project (consult) |
| `SPC f f` / `f r` / `f s` / `f S` / `f d` / `f i` | find file / recent / save / save all / dired here / open init.el |
| `SPC b b` / `b d` / `b n` / `b p` / `b r` / `b s` / `b u` | buffers / kill / next / prev / revert / scratch / undo tree (vundo) |
| `SPC p …` | the whole `project-prefix-map`: `p f` find file, `p p` switch project, `p b` buffers, `p g` grep, `p c` compile, `p k` kill buffers |
| `SPC w …` | `evil-window-map`: `w v` / `w s` split, `w h j k l` move, `w q` close, `w o` only |
| `SPC h …` | `help-map`: `h f` function, `h v` variable, `h k` key, `h m` mode |
| `SPC g g` / `g b` / `g l` / `g f` | magit status / blame / log / file dispatch |
| `SPC g n` / `g p` / `g r` | next hunk / previous hunk / revert hunk (diff-hl) |
| `SPC s s` / `s p` / `s i` / `s o` / `s m` / `s y` | line / project rg / imenu / outline / marks / kill ring |
| `SPC l a` / `l r` / `l f` / `l d` / `l R` / `l i` / `l s` / `l e` / `l q` | code action / rename / format / definition / references / implementation / workspace symbols / start eglot / stop eglot |
| `SPC e n` / `e p` / `e l` / `e b` | next error / previous / list (consult) / buffer diagnostics |
| `SPC c c` / `c r` | project compile / recompile |
| `SPC o t` / `o T` / `o d` | terminal in project root / terminal here / dired |
| `SPC t t` / `t l` / `t w` / `t f` / `t p` / `t P` | toggle theme / line numbers / word wrap / fullscreen / popup window / cycle popups |
| `SPC a c` / `a a` / `a t` | Claude Code in this project: start / transient menu / show or hide its window |
| `SPC a s` / `a r` / `a C` / `a R` / `a q` | send a prompt / send the region / continue last session / resume a session / stop |
| `SPC q q` / `q f` | quit Emacs / close frame |

Non-leader: `C-s` consult-line, `C-.` embark-act, `C-;` embark-dwim, `C-x g` magit, `C-j` / `C-k` move in vertico and corfu popups, `<` narrows a consult list (e.g. `SPC ,` then `< b` for buffers only, `< f` for files), `TAB` completes or indents, `M-+` inserts a tempel snippet by name (they also show up in the corfu popup), `M-x` still works. Ghost text from minuet in insert state: `M-a` takes one line, `M-y` takes all of it, `M-e` dismisses, `M-n` / `M-p` cycle, `M-i` asks for a suggestion now ([Claude Code](#claude-code)). Popups (`*Messages*`, `*Warnings*`, help, compilation, flymake lists, plain `eat` terminals) open in a bottom window that `SPC t p` hides and brings back.

### Languages

`treesit-auto` maps file types to tree-sitter modes and offers to install a grammar the first time you open a language (grammars compile with the system `cc`, which apt and Xcode CLT provide). eglot starts automatically in Python, JavaScript/TypeScript, Rust, Go, C/C++, Bash and Ruby buffers when a server is on PATH. `basedpyright` and `typescript-language-server` come from mise; for the other languages install the server yourself (`rust-analyzer`, `gopls`, `clangd`, `bash-language-server`, `ruby-lsp`), globally with `mise use -g` or per project with `mise use`.

apheleia formats on save with whatever formatter it knows for the mode if that binary is on PATH; missing formatter means no-op, never an error. mise installs `ruff`, `prettier` and `shfmt` globally, so Python, JS/TS/JSON/CSS/Markdown and shell format out of the box; `gofmt` and `rustfmt` arrive with their toolchains. envrc loads `.envrc` per buffer so project-local tools win. Note that a project's `.mise.toml` alone is invisible to Emacs; add an `.envrc` containing `use mise` next to it and the project's versions apply inside Emacs too.

### Look

`modus-vivendi` (dark) by default, `SPC t t` toggles to `modus-operandi`. CommitMono Nerd Font 11pt, ligatures for the common operator set, relative line numbers in code buffers, `mood-line` as a minimal mode-line, no icon packs.

### Terminal frames

`emacsclient -t` (alias `e`) gives a full Emacs inside Ghostty. Everything works except ligatures and the diff-hl fringe; corfu popups render through `corfu-terminal`. The GUI frame (`emacsclient -c`, alias `eg`) is the daily driver.

---

## Shell

`~/.zshenv` is the only file in `$HOME`; it sets `ZDOTDIR=~/.config/zsh` and sources `~/.config/zsh/.zshenv`. Everything else is in that directory.

- **`.zshenv`** runs for every zsh, including scripts: XDG variables, `~/.local/bin` first on PATH, `EDITOR`, `PAGER`, npm/python cache locations, cargo env.
- **`.zprofile`** runs for login shells. On macOS, `/etc/zprofile` runs Apple's `path_helper` after `.zshenv` and reorders PATH; `.zprofile` puts Homebrew and `~/.local/bin` back in front. On Linux it is a no-op besides the same `~/.local/bin` prepend.
- **`.zshrc`** runs for interactive shells:
  - history: 100k lines, shared between sessions, deduplicated, `HIST_IGNORE_SPACE`;
  - completion: `compinit` with a 24-hour cache, case-insensitive and partial-word matching, fzf-tab drives the menu (`<` `>` switch groups, previews for `cd`, `cp`, `mv`, `rm`, `bat`, `less`, `e`);
  - plugins in the required order: fzf-tab first, autosuggestions (`Ctrl+Space` accepts), syntax-highlighting last;
  - prompt: `➜ dir git:(branch) ✗`, pure `vcs_info`, no async worker, no prompt framework;
  - tool init is cached: `fzf --zsh`, `zoxide init`, `mise activate`, `direnv hook` each run once and the output is sourced from `~/.cache/zsh/` until the binary changes; a missing tool is silently skipped;
  - `fd` and `bat` resolve to Debian's `fdfind`/`batcat` automatically.

Keys and widgets:

| Keys | Action |
|---|---|
| `Ctrl+R` / `Ctrl+T` / `Alt+C` | fzf history / file / directory |
| `Alt+Z` | `cdi`: interactive zoxide jump |
| `Ctrl+X Ctrl+P` | `proj`: fuzzy-pick a project under `~/dev`, cd, feed zoxide |
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
- splits and tabs on `Ctrl+Shift`: `T` tab, `N` window, `W` close, `Enter` split right, `Backspace` split down, `H J K L` move between splits, `F` fullscreen.

Linux gets Ghostty from the `mkasberg/ghostty-ubuntu` release builds, which publish `.deb` files for Debian codenames; `os/linux.sh` pins the version and the SHA-256 of the trixie `amd64` and `arm64` packages, downloads the one matching your architecture, and refuses to install on a checksum mismatch. If there is no pinned build for your codename, Konsole stays and `kde/apply.sh` binds `Meta+Return` to it instead. macOS gets the official cask.

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

## Toolchains: mise

`config/mise/config.toml` is the global toolchain: `node` (LTS), `uv`, `basedpyright`, `typescript-language-server`, `typescript`. On macOS `conf.d/macos.toml` adds the CLI tools (`jq`, `fzf`, `eza`, `zoxide`, `ripgrep`, `fd`, `bat`, `delta`, `direnv`, `shellcheck`) as prebuilt binaries; on Linux apt provides the same tools and that file is not linked. Projects override with their own `.mise.toml` or `.python-version`. `mise activate zsh` runs in interactive shells; GUI apps and the Emacs daemon use the shims directory instead, which is on PATH everywhere.

```sh
mise use -g go@latest        # add a global tool
mise use python@3.13         # per project
mise upgrade                 # bump everything
```

---

## KDE

`kde/apply.sh` writes only the keys this repo owns, via `kwriteconfig6`, and leaves the rest of Plasma's config alone:

- `kxkbrc`: `caps:swapctrl`;
- `kcminputrc`: repeat delay 250 ms, rate 40/s;
- `kdeglobals`: fixed-width font CommitMono Nerd Font 11;
- `kglobalshortcutsrc`: `Meta+E` Emacs frame, `Meta+Return` terminal, `Meta+D` KRunner, `Meta+Shift+Q` close window, `Meta+H/J/K/L` focus window left/down/up/right.

Plasma 6 removed the "Custom Shortcuts" module; launching a command from a shortcut now requires a `.desktop` file (`kde/dotfiles-emacs.desktop`, hidden from menus) and a `kglobalshortcutsrc` entry keyed by its file name. `kglobalaccel` does not reliably reload; the script restarts it, and a logout applies everything for certain.

`kde/env.sh` is sourced by `startplasma` for the whole session, so every GUI app sees mise shims on PATH and `EDITOR=emacsclient -c`.

`emacs-pgtk` is installed for Wayland sessions (native Wayland, correct fractional scaling); `emacs-gtk` for X11.

---

## macOS specifics

- **Homebrew** lives in `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel); `.zprofile` detects which. `HOMEBREW_NO_ANALYTICS=1` is set globally.
- **Emacs** is `emacs-plus@30` with native compilation (the formula's default). `Emacs.app` is copied to `/Applications` because Spotlight does not index symlinks into the Homebrew cellar. The daemon is a `brew services` launchd agent running `emacs --fg-daemon`.
- **Modifiers in Emacs**: left Option is Meta, right Option is left alone for special characters, Command is Super. Command shortcuts you expect from macOS (`⌘C`, `⌘V`, `⌘Z`) are not bound; use evil.
- **Caps Lock ↔ Left Ctrl** uses `hidutil` in a LaunchAgent (`com.dotfiles.capslock`), re-applied at each login because the mapping does not persist across reboots.
- **`defaults`** applied by `os/macos/defaults.sh`; edit the list before running if you disagree with any. Dock and Finder restart automatically; keyboard settings apply after logout.
- **SSH** uses the Keychain for the key passphrase (`UseKeychain yes`).
- **No tiling manager** is installed. Sequoia's built-in tiling (`Fn+Control+arrows`) covers halves; add AeroSpace or Rectangle to the Brewfile if you want more.
- **Claude Code** is the `claude-code` Homebrew cask, so `brew upgrade` updates it.

---

## Claude Code

One posture: Claude reads, researches, debugs, reviews and plans. You write the code. The point is to keep the understanding that comes from typing it, and to have a session that knows the codebase and the goal sitting next to the buffer while you do.

### What Claude can and cannot do

- **No edits, ever.** `settings.json` denies `Edit`, `MultiEdit`, `Write` and `NotebookEdit`. A deny rule holds under every permission mode and every command-line flag; the only way to get an agent editing files is to change `settings.json`. Nothing on disk comes from a session except Claude Code's own transcripts under `~/.claude/projects`.
- **Read-only shell without prompts.** `rg`, `cat`, `head`, `tail`, `ls`, `wc`, `cut`, `jq`, `diff`, `stat`, `file`, `which`, `mise ls` and the read-only git subcommands are allowed; file finding goes through Claude's own Glob and Grep tools, which never prompt. Tools that can write or execute through a flag (`fd -x`, `tree -o`, `sort -o`) are deliberately not on the list. A shell redirection (`cat x > y`) is checked against the file rules as a write, so the `Write` deny catches it. Anything that mutates, including running your tests or a server, prompts once; `git push` is denied. Answer a prompt with "yes", not "always": "always" writes `.claude/settings.local.json` into the project (globally gitignored, but still a file).
- **No sandbox.** Commands run on the machine as you.
- **Read anywhere.** `Read(~/**)` and `/tmp`, so it can look at other repos, logs and dotfiles when the question needs it.
- `claude/CLAUDE.md` says the rest. A question gets the approach, the tradeoffs and the `file:line` involved. "Walk me through it" gets one step at a time (`file:line`, what to write, why), then Claude waits for "next" and reads your buffer before the next step, so the steps track what you actually typed.
- `/investigate <ticket | PR | path | topic>` builds a read-only brief (ticket, PR threads, code map with `file:line`, prior art, open questions) and stops. `/review <PR#>` runs the adversarial review lenses over a PR and drafts comments in your voice; you post them. Both assume a ticket tracker or code host reachable over MCP for the fetching parts and fall back to asking you to paste.

### Inside Emacs

`claude-code-ide.el` runs the real Claude Code TUI in an `eat` window, so every plugin, skill and the statusline work unchanged, and it registers Emacs as Claude's IDE over MCP: Claude sees the current buffer and selection and can read flymake diagnostics, xref, imenu and project info. `SPC a c` starts it for the current project, `SPC a r` sends the region into the prompt, `SPC a s` sends a typed prompt, `SPC a t` hides and shows the window, `SPC a C` / `a R` continue or resume a session, `SPC a a` opens the transient menu with everything else. Outside Emacs, `claude` in Ghostty is the same thing minus the buffer awareness.

### Completion: minuet

`minuet` puts multi-line ghost text under the cursor, from Gemini Flash-Lite routed through OpenRouter: a chat model, chosen because the "stay silent unless certain" rule below is an instruction, and pure fill-in-the-middle endpoints (Codestral, a local Ollama) cannot take one. OpenRouter because it is one prepaid key for any model and no Google Cloud billing to fight; at Flash-Lite prices a day of typing costs a few cents. Another model is one string in `init.el` (`:model` in `minuet-openai-compatible-options`); another provider is `minuet-provider` plus its options plist, and minuet also speaks Gemini, OpenAI, Codestral, DeepSeek, Ollama and the Anthropic API directly. It is built to stay out of the way:

- It only fires in insert state, at the end of a line, when corfu's popup is not up, at most every 1.5 seconds. LSP completion always has right of way; minuet gets the quiet spots, after a `(`, a `=`, a `:` or a newline.
- The prompt tells the model to return nothing unless the surrounding code and the conversation make the next code certain. No overlay appears for an empty answer, so a bad guess costs nothing but the request.
- One candidate, never a menu. `M-a` accepts a line, and that is the habit worth keeping; `M-y` accepts the whole block; `M-e` dismisses; typing on dismisses too. `M-i` asks for a suggestion on demand.
- The bridge to the session: when a Claude window is open for the project, the last 60 lines of it go into the completion prompt, so what you and Claude just agreed on shapes the suggestion. No file is written anywhere for this. If it turns out noisy, drop `dot/minuet-chat-tail` from `dot/minuet-prompt` in `init.el`.
- Too chatty overall: remove the `prog-mode` hook and keep `M-i`. That is on-demand mode, and some people prefer it.

The API key comes from `auth-source`: the first `M-i` asks for it and offers to save it to `~/.authinfo`, or you put it in `~/.authinfo.gpg` yourself (see [After bootstrap](#after-bootstrap)). Without a key, auto-suggestion is blocked and nothing else changes.

### The rest of `settings.json`

- **Plugins**: `typescript-lsp`, `pyright-lsp` (diagnostics for Claude's reading), `caveman` (terse answers; from a third-party marketplace, `JuliusBrussee/caveman`; drop both entries if you do not want it). Install them once with the `jq | xargs` one-liner in [After bootstrap](#after-bootstrap).
- **Statusline**: `claude/statusline.sh` shows exceptions only: model, `project:branch`, effort when it is not `high`, context usage with a hand-off warning at 25 %, and the 5h/7d rate-limit windows once they pass 50 %. One `jq` call, plus `git` for the branch.
- **Not managed**: `~/.claude/hooks` and `settings.local.json` are yours; `install.sh` never touches them, and preflight offers to keep an existing `~/.claude` whole.

---

## Upgrading

| What | Command |
|---|---|
| Everything system-level, Linux | `sudo apt update && sudo apt upgrade` (Emacs, Ghostty stays pinned, Claude Code, CLI tools) |
| Everything system-level, macOS | `brew update && brew upgrade && brew bundle --file=~/dev/dotfiles/os/Brewfile`; CLI tools ride `mise upgrade`; `mise self-update` for mise itself |
| Ghostty on Linux | bump `GHOSTTY_TAG` in `os/linux.sh`, remove the package, re-run `os/linux.sh` |
| Emacs packages | `M-x package-upgrade-all`, then `M-x package-autoremove`; `M-x package-vc-upgrade` for `claude-code-ide` |
| Toolchains and LSP servers | `mise upgrade` |
| zsh plugins | `git -C ~/dev/dotfiles submodule update --remote` |
| The dotfiles themselves | `git -C ~/dev/dotfiles pull && ~/dev/dotfiles/install.sh check` |
| KDE settings after editing `kde/apply.sh` | re-run it, log out and in |
| macOS defaults after editing | re-run `os/macos/defaults.sh` |

Re-running `bootstrap.sh` is always safe; it pulls the repo, every step checks before it acts, and preflight only asks about things it has not asked about before.

---

## Verification and CI

`.github/workflows/ci.yml` runs on every push:

- **Linux job** in a `debian:trixie` container (the exact target): installs every package in `os/apt-packages.txt` (a wrong name fails here, not on your new box), `shellcheck` on every script, `zsh -n` on every zsh file, `jq` on `settings.json`, `git config` parse, `preflight.sh` without a tty against a fake `~/.emacs.d` and `~/.gitconfig` (both must survive), then `install.sh` twice into a fresh `HOME` with a file in the way (archive path, then the stale-link path), `install.sh check`, an interactive zsh start that must print nothing, and finally Emacs 30 loads `early-init.el` + `init.el` in batch mode, installing every package from the real archives and cloning `claude-code-ide` (ELPA cache keyed on `init.el`), and byte-compiles both files.
- **macOS job**: `brew bundle` against the real `os/Brewfile` with `emacs-plus@30` (a source build) and the casks skipped, so every formula and tap name resolves; then shellcheck, `zsh -n`, `plutil -lint` on the LaunchAgent, the same preflight and double `install.sh`, interactive zsh start, and the same Emacs batch load and byte-compile with Homebrew's `emacs` formula, so the `darwin` branch of `init.el` runs for real.

Not covered: `bootstrap.sh` end to end (needs a GitHub login), `os/linux.sh`, `os/macos.sh`, `kde/apply.sh`, and anything that needs a display.

Locally: `~/dev/dotfiles/install.sh check` after anything that might have replaced a symlink.

---

## Forking

1. Fork on GitHub, then in `bootstrap.sh` change `REPO_URL`, or run it with `DOTFILES_REPO=git@github.com:you/dotfiles`.
2. Edit `os/apt-packages.txt` and `os/Brewfile` to taste.
3. Adjust `kde/apply.sh` and `os/macos/defaults.sh`; both are lists of individual settings, remove lines you do not want.
4. `claude/settings.json`: change or drop `model` (it names a specific tier), the plugins (`caveman` and its `extraKnownMarketplaces` entry point at a third-party GitHub repo), and `Read(~/**)` if you want Claude confined to your working directories. Remove the `Edit`/`Write` denies if you want an agent that edits; nothing else in the repo assumes it cannot.
5. `claude/skills/review` assumes a code host reachable over MCP or comments pasted by hand; `/investigate` works on a bare path. Delete what you do not use. `minuet` in `init.el` needs an OpenRouter API key; without one it does nothing.
6. Nothing else references a person: git identity and SSH keys are whatever the machine already has; bootstrap only checks they exist.

---

## Troubleshooting

**Shell looks wrong / plugins missing.** `~/.zshenv` must be a symlink into the repo. `install.sh check` reports it as `DRIFT`. Re-run `install.sh`.

**`compinit: insecure directories` on macOS.** `os/macos.sh` fixes permissions; re-run it, or `compaudit | xargs chmod g-w,o-w`.

**`emacsclient: can't find socket`.** The daemon is not running and `ALTERNATE_EDITOR` is not empty in this environment. `systemctl --user restart emacs` (Linux) or `brew services restart emacs-plus@30` (macOS), or just `emacsclient -a '' -c`. If bootstrap ran over SSH before your first graphical login, the unit was never enabled: `systemctl --user enable --now emacs.service`.

**Emacs ignores the repo config.** A `~/.emacs`, `~/.emacs.el` or `~/.emacs.d` exists; Emacs loads that and never looks at `~/.config/emacs`. Re-run `preflight.sh` and archive it, or move it yourself.

**Claude in Emacs: "claude not found" or it cannot see the buffer.** The daemon's PATH must contain `claude` (`emacsclient -e '(executable-find "claude")'`). On macOS `exec-path-from-shell` copies it from a login shell; on Linux it is `/usr/bin/claude` from apt. No buffer awareness means the Claude session was started outside Emacs; start it with `SPC a c` so it connects over MCP.

**minuet shows nothing.** No key yet means no auto-suggestions; `M-i` asks for the key. Otherwise check `*minuet*` (the log buffer). A 402 in the log means the OpenRouter credit ran out. Otherwise it is working as designed: the model returned nothing because it was not sure. `M-i` forces a request.

**Emacs starts but packages are missing.** First launch needs network to ELPA/MELPA. `M-x package-refresh-contents`, then `M-x package-install-selected-packages`. Corporate proxies: set `url-proxy-services` in `custom.el`.

**eglot: "no server".** Either the server was never installed (only `basedpyright` and `typescript-language-server` ship by default; `mise use -g rust-analyzer` and friends for the rest) or it is not on the daemon's PATH. `mise ls` shows what is installed; `emacsclient -e '(getenv "PATH")'` shows what the daemon sees. Restart the daemon after installing a new tool.

**Fonts look wrong in Emacs.** `fc-list | grep -i commitmono` (Linux) or Font Book (macOS) must list "CommitMono Nerd Font". Re-run `os/linux.sh` / `brew install --cask font-commit-mono-nerd-font`.

**KDE shortcut does nothing.** Log out and in; `kglobalaccel` does not always pick up file changes. Check `~/.local/share/applications/dotfiles-emacs.desktop` exists.

**Ghostty not installed on Linux.** No community build for your Debian codename. Check <https://github.com/mkasberg/ghostty-ubuntu/releases>, bump `GHOSTTY_TAG` and the `GHOSTTY_SHA256_*` values in `os/linux.sh` (the release API lists each asset's `digest`), or build from source. Konsole is bound to `Meta+Return` meanwhile.

**macOS: Caps Lock is still Caps Lock.** `launchctl list | grep capslock` should show the agent; `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.dotfiles.capslock.plist` loads it. Some keyboards need the remap re-applied after sleep; the agent runs at login only.
