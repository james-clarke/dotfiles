# dotfiles

A lean development environment for a fresh **Debian 13 + KDE Plasma 6** or **macOS** machine, built around **Lite XL** (a 5 MB native editor with LSP through plugins), a framework-free **zsh**, **Ghostty**, git, and **Claude Code** in the terminal. Two profiles decide what Claude may do: `work` lets it edit with every change behind a prompt; `personal` keeps it read-only, it investigates, plans and walks you through, you type. One Python script, `setup.py`, sets up a new box on either OS and keeps every machine in sync afterwards. apt and Homebrew own every package, every config file is a symlink into this repo, and CI proves the script, the shell and the editor config load cleanly on both platforms.

Nothing here is tied to a person or an employer. Fork it, change one URL, and it is yours.

---

## Contents

1. [What you get](#what-you-get)
2. [Install: Debian 13 + KDE](#install-debian-13--kde)
3. [Install: macOS](#install-macos)
4. [GitHub step](#github-step)
5. [After the first run](#after-the-first-run)
6. [Repository layout](#repository-layout)
7. [How the pieces fit](#how-the-pieces-fit)
8. [Editor: Lite XL](#editor-lite-xl)
9. [Shell](#shell)
10. [Terminal: Ghostty](#terminal-ghostty)
11. [Git](#git)
12. [Toolchains](#toolchains)
13. [KDE](#kde)
14. [macOS specifics](#macos-specifics)
15. [Claude Code](#claude-code)
16. [Upgrading: setup.py](#upgrading-setuppy)
17. [Verification and CI](#verification-and-ci)
18. [Forking](#forking)
19. [Troubleshooting](#troubleshooting)

---

## What you get

| Area | Choice | Why |
|---|---|---|
| Editor | Lite XL 2.1.8, portable install under `~/.local` (Debian) or `/Applications` (macOS), one `init.lua` for both | Starts in well under 100 ms, ~5 MB, Lua-configured, native Wayland (SDL3) and native on M1 |
| Editor plugins | `lsp` + `lsp_snippets` + `snippets`, `language_ts`, `autoinsert`, `bracketmatch`, `indentguide`, `gitdiff_highlight`, `editorconfig`; installed by `lpm` from `os/lite-xl-plugins.txt` | Completion, diagnostics, rename and go-to-definition for Python and TypeScript, nothing else |
| LSP servers | `basedpyright` + `ruff server`, `typescript-language-server`, from `uv tool` / `npm -g` / Homebrew | Same binaries the shell uses; the editor resolves them by absolute path |
| Shell | zsh, no framework | `~/.zshenv` stub + `~/.config/zsh/`; plugins as git submodules; cached tool init |
| Terminal | Ghostty | One config file for KDE and macOS; GPU fast; Meta passes through cleanly |
| Toolchains | apt / Homebrew; `uv tool` and `npm -g` under `~/.local` on Debian for what apt lacks | No version manager, no shims; upgrades ride the package manager |
| Git | delta pager, sane defaults | Identity, keys and signing stay whatever the machine already has |
| Keyboard | Caps Lock ↔ Left Ctrl: `keyd` on Debian, `hidutil` on macOS | Kernel-level on Linux (works in SDDM and a TTY, no Wayland regressions); no background process on macOS |
| Fonts | CommitMono Nerd Font | Ligatures + icons, installed by `setup.py` |
| AI | Claude Code CLI in Ghostty | `work` profile: it edits, each change prompts. `personal` profile: it cannot edit; it investigates, plans and walks you through, you type |
| Sync | `setup.py` | Pulls the repo, re-links, upgrades apt/Homebrew, the tools and the editor plugins, re-applies KDE or macOS settings when their tables changed |

Package counts stay small on purpose: nine editor plugins, no Electron, no daemon for the editor. `setup.py` is standard-library Python and runs on the Python 3.9 that macOS Command Line Tools ship, so nothing has to be installed before it.

---

## Install: Debian 13 + KDE

1. Install Debian 13 from the netinst with **KDE Plasma** and **standard system utilities** (that includes `python3`). Log in once so Plasma creates its config directories.

2. Install git, clone over HTTPS (the repo is public, no key needed yet) and run the setup with the profile for this machine (`work` or `personal`, see [Claude Code](#claude-code); it is remembered in `~/.local/state/dotfiles/profile`, so later runs need no flag):
   ```sh
   sudo apt install -y git
   git clone --recurse-submodules https://github.com/james-clarke/dotfiles ~/dev/dotfiles
   python3 ~/dev/dotfiles/setup.py --profile work
   ```
   Three things during the run need you: the sudo password, a passphrase for the new SSH key, and a browser login to GitHub (`gh` shows a one-time code). What it does, in order:
   - `git pull --ff-only` and `git submodule update` (a no-op right after the clone);
   - links every config file into place ([Where things land](#where-things-land)); anything already there is renamed `<file>.bak`;
   - `apt-get update`, installs everything in `os/apt-packages.txt` (including `keyd`, `wl-clipboard`, `gh`, `nodejs`, `npm`, `pipx`, `shfmt`), then `apt-get upgrade`;
   - `pipx install uv`, then `uv tool install` for `os/uv-tools.txt` (`ruff`, `basedpyright`, `djlint`) and `npm install -g` for `os/npm-packages.txt` (`typescript`, `typescript-language-server`, `prettier`), all under `~/.local`, no sudo;
   - downloads CommitMono Nerd Font into `~/.local/share/fonts` and refreshes the font cache;
   - installs Lite XL (pinned release, SHA-256 checked) into `~/.local/share/lite-xl` with `lite-xl` on `~/.local/bin`, then `lpm` and the plugins in `os/lite-xl-plugins.txt`;
   - installs Ghostty from the community `.deb` build (pinned version and SHA-256) or leaves Konsole in place if no build exists for your Debian codename;
   - writes `/etc/keyd/default.conf` (Caps Lock ↔ Left Ctrl) and enables the `keyd` service;
   - adds the Claude Code apt repository (GPG fingerprint verified) and installs `claude-code`; same for Google Chrome on `amd64`;
   - sets zsh as the login shell;
   - the [GitHub step](#github-step): SSH key, `gh auth login`, key upload, git identity, and the repo remote switched to SSH;
   - applies the KDE settings if you are inside a Plasma session (otherwise it tells you to run it again after login);
   - remembers what it applied (profile, links, KDE and macOS tables, editor versions) in `~/.local/state/dotfiles`, so later runs only redo what changed.

   Add `--dry-run` to see every command it would run without running any.

3. Log out and back in. This activates the zsh login shell, the Plasma session environment (`EDITOR`, `PATH`, the SSH askpass), the keyboard remap and the global shortcuts.

4. Continue at [After the first run](#after-the-first-run).

---

## Install: macOS

1. `xcode-select --install` provides git and `python3`. Clone over HTTPS and run the setup with the profile for this machine:
   ```sh
   git clone --recurse-submodules https://github.com/james-clarke/dotfiles ~/Developer/dotfiles
   python3 ~/Developer/dotfiles/setup.py --profile personal
   ```
   (`~/Developer` gets its own Finder icon; the rest of this README writes `~/dev/dotfiles`.) It needs you for the sudo password (Homebrew), a passphrase for the new SSH key, and a browser login to GitHub. What it does, in order:
   - `git pull --ff-only` and `git submodule update`;
   - links every config file into place; anything already there is renamed `<file>.bak`;
   - installs Homebrew if missing (the only thing curl-piped in this repo), then `brew update`, `brew bundle` against `os/Brewfile`, `brew upgrade`, `brew autoremove`, `brew cleanup`. Formulas: `git`, `gh`, `node`, `uv`, `ruff`, `shfmt`, `basedpyright`, `typescript-language-server`, `typescript`, `prettier`, `djlint`, `jq`, `fzf`, `eza`, `zoxide`, `ripgrep`, `fd`, `bat`, `git-delta`, `direnv`, `shellcheck`. Casks: Ghostty, Claude Code, the Nerd Font;
   - installs Lite XL from the pinned `.dmg` (SHA-256 checked, quarantine flag removed so it opens without the right-click dance) into `/Applications`, links `lite-xl` into `~/.local/bin`, then `lpm` and the plugins;
   - installs a LaunchAgent that swaps Caps Lock and Left Ctrl at every login (`hidutil`);
   - makes `/bin/zsh` the login shell if it is not;
   - fixes the Homebrew completion-directory permissions that otherwise trigger `compinit` warnings;
   - the [GitHub step](#github-step): SSH key (stored in the Keychain), `gh auth login`, key upload, git identity, and the repo remote switched to SSH;
   - applies the `defaults` table (fast key repeat, no press-and-hold accents, no smart quotes, reduced motion and transparency, Finder shows extensions and hidden files, Dock autohide, hot corners off, no window restore at login, no `.DS_Store` on USB or network shares, Handoff off) on the first run and whenever the table changes.

2. Log out and back in (or reboot) so the keyboard remap, key repeat, reduced motion and login shell environment apply everywhere.

3. Continue at [After the first run](#after-the-first-run).

---

## GitHub step

Both installs end with the same step, and it is why a fresh machine needs no manual git setup. Every part checks first and skips itself when done, so re-running is free:

1. `~/.ssh/config` gets `AddKeysToAgent yes` (plus `UseKeychain yes` on macOS), so the passphrase is asked once per login and then held by the agent: Debian's user `ssh-agent.service` with `ksshaskpass` as the prompt (it offers to store the passphrase in KWallet), launchd's agent and the Keychain on macOS.
2. `ssh-keygen -t ed25519` if `~/.ssh/id_ed25519` does not exist. It asks for a passphrase.
3. `gh auth login --web --git-protocol ssh --scopes admin:public_key` if `gh` is not logged in: it prints a one-time code and opens the browser. This is the only interactive login on the machine; Claude Code and Homebrew have their own.
4. `gh ssh-key add ~/.ssh/id_ed25519.pub --title <hostname>` unless that key is already on the account.
5. If `git config --global user.name` / `user.email` are unset, it asks for them, offering your GitHub profile name and the `<id>+<login>@users.noreply.github.com` address as defaults (Enter accepts). Nothing else touches `~/.gitconfig`; commit signing, if you want it, is yours to add.
6. The repo remote is switched from the HTTPS clone URL to `git@github.com:...`, then `ssh -T git@github.com` is checked. If the agent does not hold the key yet it says so; the first `git pull` will prompt for the passphrase and load it.

---

## After the first run

1. Open a terminal (Ghostty). The prompt is `➜ dir git:(branch)`.

2. Log in to Claude Code and install the plugins the settings file expects:
   ```sh
   claude
   jq -r '.enabledPlugins | keys[]' ~/.claude/settings.json | xargs -n1 claude plugin install
   ```

3. Verify that every symlink survived (Claude's `/model` command and some apps rewrite files; this catches it):
   ```sh
   python3 ~/dev/dotfiles/setup.py check
   ```

4. Open the editor: `Meta+E` on KDE, Spotlight → "Lite XL" on macOS, or `e file` in any terminal. Open a `.py` or `.ts` file and the language servers start; `Ctrl+Space` completes, `Alt+D` jumps to a definition, `Alt+R` renames (see [Editor: Lite XL](#editor-lite-xl)).

5. Linux only, if the first run happened outside a Plasma session (over SSH, before the first login): run `python3 ~/dev/dotfiles/setup.py` again now, then log out and in.

---

## Repository layout

```
setup.py                the one command: pull, link, install/upgrade, daemons, KDE/defaults; `link`, `check`, `--dry-run`
os/
  apt-packages.txt      flat apt list
  npm-packages.txt      npm -g list (Debian only; Homebrew formulas on macOS)
  uv-tools.txt          uv tool list (Debian only; Homebrew formulas on macOS)
  Brewfile              tap, formulas, casks
  lite-xl-plugins.txt   lpm plugin list
  macos/capslock.plist  LaunchAgent: Caps Lock <-> Left Ctrl
lite-xl/init.lua        the whole editor config: font, indent, ignored dirs, the language servers
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
  env.sh                Plasma session env (PATH, EDITOR) for GUI apps
  dotfiles-editor.desktop hidden launcher (lite-xl %F) bound to Meta+E, default for text/plain
claude/
  common.md             rules shared by both profiles (imported by the CLAUDE.*.md files)
  CLAUDE.work.md        write-mode posture: Claude edits, every change prompts
  CLAUDE.personal.md    read-only posture: Claude investigates and walks you through
  settings.work.json    permissions (edits allowed, prompts kept), plugins, statusline
  settings.personal.json permissions (edits denied), plugins, statusline
  statusline.sh         model / effort / project / branch / context / rate-limit line
  skills/investigate/   /investigate: read-only brief of a ticket, PR or area
  skills/review/        /review: PR review and re-review, drafts only
ruff.toml               lint settings for setup.py (target Python 3.9)
.github/workflows/ci.yml  Linux (Debian container) + macOS checks
```

The KDE settings (`kwriteconfig6` keys) and the macOS `defaults` list live as tables at the top of `setup.py`, next to the pinned Lite XL, `lpm`, Ghostty and Nerd Font versions with their SHA-256 digests, and the GPG fingerprints.

### Where things land

| Repo file | Symlink target |
|---|---|
| `zsh/home.zshenv` | `~/.zshenv` |
| `zsh/` | `~/.config/zsh/` |
| `lite-xl/init.lua` | `~/.config/lite-xl/init.lua` (`plugins/` and `libraries/` next to it are written by `lpm`, untracked) |
| `ghostty/config` | `~/.config/ghostty/config` |
| `config/git/*` | `~/.config/git/` |
| `claude/settings.<profile>.json` | `~/.claude/settings.json` |
| `claude/CLAUDE.<profile>.md` | `~/.claude/CLAUDE.md` |
| `claude/common.md`, `claude/statusline.sh`, `claude/skills` | `~/.claude/` |
| `kde/env.sh` (Linux) | `~/.config/plasma-workspace/env/dotfiles.sh` |
| `kde/dotfiles-editor.desktop` (Linux) | `~/.local/share/applications/` |

`setup.py` records the targets in `~/.local/state/dotfiles/links` and removes links from earlier runs whose entry has since left the table (switching profiles, or a file that moved). Files that must not be symlinks (Plasma rewrites its rc files atomically, launchd wants a real plist, `keyd` reads `/etc`) are written by the script instead.

---

## How the pieces fit

**Editor everywhere.** `EDITOR` and `VISUAL` are `lite-xl` in shells (`.zshenv`) and in the Plasma session (`kde/env.sh`). Each invocation is its own process that exits when its window closes, so `git commit`, `crontab -e` and `Ctrl+X Ctrl+G` from the shell block the way they should; no single-instance plugin is installed for that reason. `lite-xl path:line` opens at a line.

**One PATH story.** `~/.local/bin` first (on Debian that is where `uv tool`, `npm -g` via `npm_config_prefix`, `pipx` and the `bat`/`fd` shims put their binaries), then Homebrew's `bin` on macOS, then the system. Shells get it from `.zshenv`, so scripts, `ssh mac cmd` and the editor's LSP servers see the same PATH as a terminal. GUI apps get it from the Plasma session env on Linux and from `exec-path-from-shell` on macOS. Lite XL launched from Spotlight or a KDE shortcut may see a shorter PATH, so `init.lua` resolves the language servers by absolute path (`~/.local/bin`, then Homebrew).

**Keyboard.** Caps Lock and Left Ctrl are swapped on both OSes, which makes every `Ctrl` chord comfortable. On Debian `keyd` does it at the kernel input level (`/etc/keyd/default.conf`), so it holds in Plasma, SDDM and a TTY alike and does not depend on the XKB option that has regressed across Plasma releases; on macOS it is `hidutil`. Key repeat is fast on both. `Meta+E` (KDE) opens the editor, `Meta+Return` a terminal, `Meta+D` KRunner; `Meta+Arrows` focus the window in that direction, `Meta+Shift+Arrows` tile it to that edge, `Meta+F` maximizes, `Meta+Shift+F` goes fullscreen, `Meta+Shift+Q` closes. On macOS, Option sends Alt in Ghostty; Command stays Command. Window tiling there is macOS' own (Window > Move & Resize, or drag to a screen edge; `Fn+Ctrl+Arrows` by default).

**Package managers own upgrades.** apt installs Ghostty, Claude Code, node and the CLI tools on Debian; `uv tool` and `npm -g` add the language servers apt does not carry. Homebrew installs all of it on macOS, as formulas and casks. Lite XL and `lpm` are the two things neither has: pinned GitHub releases, SHA-256 checked, installed without root. `lpm` installs and upgrades the editor plugins. `setup.py` runs every upgrade. Nothing is curl-piped except Homebrew's installer.

---

## Editor: Lite XL

[Lite XL](https://lite-xl.com) is a small native editor: a C core with SDL3 rendering, everything else Lua. It starts faster than a terminal, uses a few tens of MB with a project open, and does exactly what the plugins say. The choice here is deliberate for both machines: on the M1 with 8 GB it leaves the memory to the work; on the work box it keeps the keyboard-driven flow without an Electron process.

### Install and upgrade

There is no apt package and no Homebrew cask, so `setup.py` owns it: the pinned release (`LITE_XL_TAG`) is downloaded from GitHub, its SHA-256 checked against the digest recorded in the script, and installed without root: the portable tarball into `~/.local/share/lite-xl` on Debian, the arm64 `.dmg` copied to `/Applications/Lite XL.app` on macOS. `~/.local/bin/lite-xl` points at the binary on both, which is what `EDITOR`, the `e` alias and the KDE launcher use. The installed tag is remembered in `~/.local/state/dotfiles/lite-xl`; bumping the tag and digest in `setup.py` upgrades every machine on its next run.

Plugins come through [`lpm`](https://github.com/lite-xl/lite-xl-plugin-manager), also pinned and checksummed, into `~/.config/lite-xl/plugins/`. The list is `os/lite-xl-plugins.txt`; `setup.py` runs `lpm install --assume-yes` on it (idempotent) and then `lpm upgrade`. `lpm` is always told the plugin API level (`--mod-version`) rather than asked to probe the binary, because probing launches the editor.

### Plugins

| Plugin | What |
|---|---|
| `lsp`, `lsp_snippets`, `snippets` | Completion, hover, diagnostics, go-to-definition, rename, symbol search from any LSP server; snippet-form completions |
| `language_ts` | TypeScript/TSX syntax (JavaScript and Python ship with the core) |
| `autoinsert`, `bracketmatch`, `indentguide` | closing pairs, matching-bracket underline, indent guides |
| `gitdiff_highlight` | changed lines in the gutter |
| `editorconfig` | honours a project's `.editorconfig` |
| bundled: `treeview`, `projectsearch`, `autoreload`, `trimwhitespace`, `contextmenu`, `scale`, `tabularize`, and the rest of `data/plugins` | file tree, project-wide search, reload on disk change, and so on |

Not installed on purpose: `terminal` (Ghostty is the terminal, a split away), `minimap`, `ipc` (single-instance mode would break `git commit` waiting for the editor), `autosave`, `lsp_python` / `lsp_typescript` (they download their own server binaries; the servers here come from `uv`, `npm` and Homebrew and are shared with the shell).

### Config

`lite-xl/init.lua` is the whole config, linked to `~/.config/lite-xl/init.lua` on both OSes (the search order is the same on macOS). It sets CommitMono Nerd Font 13/12pt when the font file is present (the bundled JetBrains Mono otherwise), 4-space soft tabs, a guide at 100 columns, the ignored directories (`.git`, `.venv`, `node_modules`, `__pycache__`, caches, `dist`, `build`), and registers the language servers with the `lsp` plugin: `basedpyright-langserver --stdio` and `ruff server` for `.py`, `typescript-language-server --stdio` for `.js`/`.jsx`/`.ts`/`.tsx`. All are located by absolute path (`~/.local/bin`, then `/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`), so the editor finds them even when launched from Spotlight or a KDE shortcut with a minimal PATH. Everything else is the editor's defaults; the command palette (`Ctrl+Shift+P`) lists every command with its binding.

### Keys worth knowing

| Keys | Action |
|---|---|
| `Ctrl+P` / `Ctrl+Shift+P` | open file by fuzzy name / command palette |
| `Ctrl+F` / `Ctrl+R` / `Ctrl+Shift+F` | find / replace / search the project |
| `Ctrl+G` | go to line |
| `Ctrl+Space` / `Ctrl+Shift+Space` | completion / signature help (`lsp`) |
| `Alt+D` / `Alt+Shift+D` / `Alt+F` | go to definition / implementation / find references (`lsp`) |
| `Alt+R` / `Alt+A` | rename symbol / symbol info under the cursor (`lsp`) |
| `Alt+E` / `Ctrl+Alt+E` | diagnostics of this file / of the project (`lsp`) |
| `Alt+S` / `Alt+Shift+S` | document symbols / workspace symbol search (`lsp`) |
| `Alt+Shift+F` | format document through the server: `ruff server` for Python, `typescript-language-server` for TS (`lsp`) |
| `Ctrl+D` / `Ctrl+Shift+L` | select next occurrence / select all occurrences (multi-caret) |
| `Ctrl+Shift+K` / `Ctrl+Shift+D` | delete line / duplicate line |
| `Ctrl+/` | toggle comment |
| `Ctrl+Shift+Up` / `Ctrl+Shift+Down` | add a caret on the line above / below |
| `Ctrl+W` / `Ctrl+Tab` | close tab / next tab |
| `Alt+Shift+J` / `Alt+Shift+L` / `Alt+Shift+I` / `Alt+Shift+K` | split left / right / up / down |
| `Alt+J` / `Alt+L` / `Alt+I` / `Alt+K` | move to the split in that direction |
| `Ctrl+O` / `Ctrl+Shift+O` | open a file / open a project directory |

On macOS `Ctrl` reads as `Cmd` for the editor's own bindings (`⌘P`, `⌘⇧P`, `⌘S`), and Caps Lock is Ctrl for everything else.

### Formatting and linting

Python gets two servers: `basedpyright` for types, completion and navigation, and `ruff server` for lint diagnostics and formatting, so `Alt+Shift+F` is `ruff format` and the ruff rules show inline. TypeScript formatting comes from `typescript-language-server`; `prettier -w` from the shell for anything it should own. No format-on-save plugin, on purpose: `editorconfig` keeps indentation honest while typing and the formatter runs when you ask.

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
| `Ctrl+X Ctrl+G` | live ripgrep across the tree with preview; Enter opens the hit at that line in the editor (`$EDITOR +line file`) |
| `Alt+←` / `Alt+→` / `Alt+B` / `Alt+F` | word motion (all common terminal escape sequences bound) |

Aliases: `ls`/`la` (eza with icons), `e` (`lite-xl`), `cp`/`rm`/`mkdir` verbose and interactive, `df -h`. `man` pages render through `bat`.

Startup is well under 50 ms because nothing is evaluated at shell start that can be cached.

---

## Terminal: Ghostty

`ghostty/config` is identical on both OSes:

- CommitMono Nerd Font 12pt, Catppuccin Latte/Mocha following the system light/dark setting;
- zsh shell integration (cursor shape, sudo prompt, titles), block cursor, no blink;
- copy on select, no close confirmation, small padding;
- `macos-option-as-alt = true` so Option sends Alt to terminal programs (fzf, zsh word motion);
- splits and tabs on `Ctrl+Shift`: `T` tab, `N` window, `W` close, `Enter` split right, `Backspace` split down, `Arrows` move between splits, `F` fullscreen.

Linux gets Ghostty from the `mkasberg/ghostty-ubuntu` release builds, which publish `.deb` files for Debian codenames; `setup.py` pins the version and the SHA-256 of the trixie `amd64` and `arm64` packages, downloads the one matching your architecture, and refuses to install on a checksum mismatch. `setup.py` compares the installed package version with the pin, so bumping `GHOSTTY_TAG` upgrades every machine on its next sync. If there is no pinned build for your codename, Konsole stays and the KDE step binds `Meta+Return` to it instead. macOS gets the official cask.

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

No version manager. Each tool comes from the package manager that has it, and `setup.py` upgrades all of them:

| Tool | Debian | macOS |
|---|---|---|
| `node`, `npm` | apt (`nodejs` 20, the Debian 13 release) | `brew "node"` (current) |
| `uv` | `pipx install uv` (apt has `pipx`, not `uv`) | `brew "uv"` |
| `ruff`, `basedpyright` | `uv tool install`, from `os/uv-tools.txt` | Homebrew formulas |
| `typescript`, `typescript-language-server`, `prettier` | `npm install -g`, from `os/npm-packages.txt` | Homebrew formulas |
| `shfmt`, `jq`, `fzf`, `eza`, `zoxide`, `ripgrep`, `fd`, `bat`, `delta`, `direnv`, `shellcheck` | apt | Homebrew formulas |

On Debian everything user-installed lands under `~/.local` (`npm_config_prefix` is set in `.zshenv` and by `setup.py`), so nothing needs sudo and nothing fights apt. Per-project versions are the project's business (`.envrc`, a virtualenv, `npx`); nothing global changes per directory.

To add a tool for every machine: apt name into `os/apt-packages.txt`, formula into `os/Brewfile`, and for Debian-only gaps a line in `os/uv-tools.txt` or `os/npm-packages.txt`; then `setup.py`.

---

## KDE

The KDE step of `setup.py` writes only the keys this repo owns (the `KDE_KEYS` table at the top of the script), via `kwriteconfig6`, and leaves the rest of Plasma's config alone:

- `kxkbrc`: the `Options` key is deleted and `ResetOldOptions` set, so no XKB-level swap is left behind; `keyd` owns the Caps Lock ↔ Ctrl remap;
- `kcminputrc`: repeat delay 250 ms, rate 40/s;
- `kdeglobals`: fixed-width font CommitMono Nerd Font 11;
- `kglobalshortcutsrc`: `Meta+E` editor, `Meta+Return` terminal, `Meta+D` KRunner, `Meta+Shift+Q` close window, `Meta+Arrows` focus the window in that direction, `Meta+Shift+Arrows` quick-tile it there (Plasma's default `Meta+Shift+Left/Right`, move to the previous or next screen, is unset so the tile keys win), `Meta+F` maximize, `Meta+Shift+F` fullscreen.

Plasma 6 removed the "Custom Shortcuts" module; launching a command from a shortcut requires a `.desktop` file (`kde/dotfiles-editor.desktop`, hidden from menus, also the default handler for `text/plain`) and a `kglobalshortcutsrc` entry under `[services]` keyed by the file name with a bare key sequence as the value. `kglobalaccel` does not reliably reload; the script restarts it, and a logout applies everything for certain. `setup.py` runs the step on the first sync and whenever the table changes (it keeps a hash in `~/.local/state/dotfiles/kde`), when it is inside a Plasma session; otherwise it tells you to run it again after login.

`keyd` is the keyboard remapper: `/etc/keyd/default.conf` maps `capslock` to `leftcontrol` and back, the service runs as root and rewrites events before any compositor sees them. `sudo keyd monitor` shows what it does, `sudo keyd reload` after editing the file.

`kde/env.sh` is sourced by `startplasma` for the whole session, so every GUI app sees `~/.local/bin` on PATH, `EDITOR=lite-xl`, and `SSH_ASKPASS=ksshaskpass` with `SSH_ASKPASS_REQUIRE=prefer`, so the SSH passphrase prompt is a KWallet-backed dialog from any terminal or GUI app. The agent itself is Debian's user `ssh-agent.service`, started with every graphical session.

Lite XL 2.1.8 is built on SDL3, which picks Wayland natively on Plasma. `wl-clipboard` provides `wl-copy` / `wl-paste` for scripts and the shell; Lite XL and Ghostty talk to the Wayland clipboard themselves.

---

## macOS specifics

- **Homebrew** lives in `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel); `.zshenv` detects which, so non-login shells and the editor see it too. `HOMEBREW_NO_ANALYTICS=1` is set globally. CLI tools and language servers are formulas; the login shell stays `/bin/zsh` (Homebrew's `zsh` is not installed).
- **Lite XL** has no Homebrew cask, so `setup.py` installs the arm64 `.dmg` from the pinned GitHub release itself: mount, copy `Lite XL.app` to `/Applications`, unmount, strip the quarantine attribute (the release is not notarized; the SHA-256 check stands in for Gatekeeper). `~/.local/bin/lite-xl` links to the binary inside the bundle, so `EDITOR`, `e file` and `git commit` use the same app as Spotlight. The editor's own bindings use `Cmd` where this README writes `Ctrl` (`⌘P`, `⌘⇧P`, `⌘S`).
- **Caps Lock ↔ Left Ctrl** uses `hidutil` in a LaunchAgent (`com.dotfiles.capslock`), re-applied at each login because the mapping does not persist across reboots. No Karabiner: a single-key remap does not need a resident process.
- **`defaults`** come from the `MACOS_DEFAULTS` table in `setup.py`; edit the table if you disagree with any. Dock and Finder restart automatically; keyboard, accessibility (`reduceMotion`, `reduceTransparency`: the same switches as System Settings > Accessibility > Display, written from the terminal and picked up at the next login) and login-restore settings apply after logout. Hot corners are off, Handoff is off (`-currentHost` keys, the one row not verified against a primary Sequoia source), no `.DS_Store` on USB or network shares. Skipped on purpose: `DisableAllAnimations` (no-op for years) and the screenshot-shadow key (does not stick on 15). The script re-applies the table only when it changed (hash in `~/.local/state/dotfiles/defaults`).
- **Spotlight** cannot be excluded from `node_modules` by script on 15 (`.metadata_never_index` is ignored now): add `~/Developer` under System Settings > Spotlight > Search Privacy, once, by hand. Apple Intelligence, Siri and analytics sharing are System Settings toggles too; `defaults` keys for them are unreliable, so the table leaves them alone.
- **SSH** uses the Keychain for the key passphrase (`UseKeychain yes`).
- **Window tiling** is macOS' own: drag a window to an edge, use Window > Move & Resize, or `Fn+Ctrl+Arrows`. No third-party tiler.
- **8 GB of RAM.** Nothing in the Brewfile runs as a background service. No Docker Desktop (it idles at several GB; `colima` if a container runtime is ever needed), no Electron editors or chat clients as daily drivers.
- **Claude Code** is the `claude-code` Homebrew cask. It and Ghostty update themselves, which is why plain `brew upgrade` skips them; `brew upgrade --greedy` forces a Homebrew-side update.

---

## Claude Code

Two profiles, picked once per machine with `setup.py --profile work|personal` and switchable any time with `python3 ~/dev/dotfiles/setup.py link --profile <other>`. They differ in one settings file and one posture file; everything else (plugins, statusline, skills, the shared rules in `claude/common.md`) is the same.

**`work`**: productivity. Claude edits, creates and refactors, and every edit prompts, so you see each change before it lands (answer "yes, don't ask again" and it stops asking for that project: that writes `.claude/settings.local.json` there). Mutating shell commands prompt the same way. `CLAUDE.work.md` says: implement what is asked, smallest diff, ask with a question when a decision is yours, report test output exactly.

**`personal`**: learning. Claude reads, researches, debugs, reviews and plans. You write the code. `settings.personal.json` denies `Edit`, `Write` and `NotebookEdit`; a deny rule holds under every permission mode and every command-line flag, so the only way to get an agent editing is to switch profiles. `CLAUDE.personal.md` says: no edits, no files, answer with approach, tradeoffs and `file:line`; "walk me through it" gets one step at a time and Claude reads your buffer before the next.

### Shared by both profiles

- **Read-only shell without prompts.** Both allow lists cover `rg`, `cat`, `head`, `tail`, `ls`, `wc`, `jq`, `diff`, `stat`, `file`, `which`, `uname`, `test`, the read-only git subcommands including `git fetch` and `git ls-remote`, the read-only `gh` views, `brew list`/`info`, `launchctl list`/`print`, `defaults read`, and the checkers (`ruff check`, `ruff format --check`, `basedpyright`, `tsc --noEmit`, `prettier --check`, `shfmt -d`). Claude Code matches each part of a `a && b` or `a | b` chain separately, so every part has to be on the list for the chain to pass; that is why the list is long. File finding goes through Claude's own Glob and Grep tools, which never prompt. Tools that can write or execute through a flag (`fd -x`, `tree -o`, `sort -o`, `xargs`, `awk`) are deliberately not on it. A shell redirection (`cat x > y`) is checked as a write.
- **`git push` is denied** in both profiles. Push yourself.
- **No sandbox.** Commands run on the machine as you.
- **Read anywhere.** `Read(~/**)` and `/tmp`, so it can look at other repos, logs and dotfiles when the question needs it.
- `claude/common.md` carries the rest: caveman mode (terse answers), ask-before-guessing, `file:line` citations, model tiering for subagents, context hygiene and the 250K hand-off rule.
- `/investigate <ticket | PR | path | topic>` builds a read-only brief (ticket, PR threads, code map with `file:line`, prior art, open questions) and stops. `/review <PR#>` runs the adversarial review lenses over a PR and drafts comments in your voice; you post them. Both assume a ticket tracker or code host reachable over MCP for the fetching parts and fall back to asking you to paste.

### Where it runs

`claude` in Ghostty, in the project directory. There is no editor integration: Claude reads files through its own tools, and the LSP plugins (`typescript-lsp`, `pyright-lsp`) give it diagnostics. A split (`Ctrl+Shift+Enter`) puts the session next to a second shell; on `personal` you type in Lite XL while Claude explains in the terminal.

### The rest of `settings.<profile>.json`

- **Plugins**: `typescript-lsp`, `pyright-lsp` (diagnostics for Claude's reading), `caveman` (terse answers; from a third-party marketplace, `JuliusBrussee/caveman`; drop both entries if you do not want it). Install them once with the `jq | xargs` one-liner in [After the first run](#after-the-first-run).
- **Statusline**: `claude/statusline.sh` shows exceptions only: model, `project:branch`, effort when it is not `high`, context usage with a hand-off warning at 25 %, and the 5h/7d rate-limit windows once they pass 50 %. One `jq` call, plus `git` for the branch.
- **Not managed**: `~/.claude/hooks` and any project's `.claude/settings.local.json` are yours; `setup.py` never touches them.

---

## Upgrading: setup.py

`python3 ~/dev/dotfiles/setup.py` is the one command. Run it on any machine after pushing changes from another, or just to upgrade:

- `git pull --ff-only` in the repo (a failure, offline or diverged, is reported and the run continues with the local tree) and `git submodule update`;
- re-links every file (`setup.py link` alone does just this; `setup.py check` verifies every link and exits 1 on drift);
- Debian: `apt-get update` + install + `upgrade`, `pipx upgrade-all`, `uv tool upgrade --all`, `npm install -g` of the list (which upgrades), the Ghostty pin, `keyd`, the daemon unit, Claude Code, Chrome; macOS: `brew update`, `brew bundle`, `brew upgrade`, `brew autoremove`, `brew cleanup`, the LaunchAgents;
- `lpm install` of the plugin list (idempotent) and `lpm upgrade`;
- re-applies the KDE table (inside Plasma) or the macOS `defaults` table if it changed;
- prints the manual tail: new terminal, log out and in, `setup.py check`.

Every step checks before it acts, so re-running is always safe; `--dry-run` prints what a run would do. What `setup.py` does not do:

| What | Command |
|---|---|
| Lite XL or `lpm` itself | bump `LITE_XL_TAG` / `LPM_TAG` and the digests in `setup.py` (the GitHub release API lists each asset's `digest`), push, `setup.py` |
| zsh plugins | `git -C ~/dev/dotfiles submodule update --remote`, commit, push, `setup.py` elsewhere |
| Ghostty on Linux | bump `GHOSTTY_TAG` and `GHOSTTY_SHA256` in `setup.py`, push, `setup.py` |
| Self-updating casks on macOS (Ghostty, Claude Code) | they update themselves; `brew upgrade --greedy` forces it |

---

## Verification and CI

`.github/workflows/ci.yml` runs on every push:

- **Linux job** in a `debian:trixie` container (the exact target): installs every package in `os/apt-packages.txt` (a wrong name fails here, not on your new box), installs every entry of `os/uv-tools.txt` and `os/npm-packages.txt` into a throwaway `HOME` and checks each binary landed in `~/.local/bin`, `ruff check` on `setup.py` (target Python 3.9, so a 3.10+ construct fails here), `shellcheck` on `statusline.sh`, `zsh -n` on every zsh file, `jq` on both settings files, `git config` parse, then `setup.py link --profile work` twice into a fresh `HOME` with a file in the way (the `moved` path, then the stale-link path), `setup.py check`, the same `link` and `check` under a real Python 3.9 from `uv`, a full `setup.py --dry-run` (every step runs its checks and prints its commands, nothing is installed), `luac -p` on `lite-xl/init.lua`, and an interactive zsh start that must print nothing.
- **macOS job**: `brew bundle` against the real `os/Brewfile` with the casks skipped, so every tap, formula and cask name resolves and the formulas install for real; then `ruff check`, shellcheck, `zsh -n`, `plutil -lint` on both LaunchAgents, the same double `link`, `check` and `--dry-run` with `--profile personal`, `luac -p`, and the interactive zsh start.

Not covered: a real `setup.py` sync (needs sudo, a display and a GitHub login), and the editor itself (needs a display).

Locally: `python3 ~/dev/dotfiles/setup.py check` after anything that might have replaced a symlink; `ruff check setup.py` after editing the script.

---

## Forking

1. Fork on GitHub and clone your fork over HTTPS; the README's clone lines are the only place the URL appears, and the GitHub step switches whatever remote it finds to SSH.
2. Edit `os/apt-packages.txt`, `os/Brewfile`, `os/uv-tools.txt` and `os/npm-packages.txt` to taste.
3. Adjust the `KDE_KEYS` and `MACOS_DEFAULTS` tables in `setup.py`; both are lists of individual settings, remove lines you do not want. Drop `keyd` from the apt list and the `linux_keyd` call if you do not want the Caps Lock swap.
4. `claude/settings.*.json`: change or drop `model` (it names a specific tier), the plugins (`caveman` and its `extraKnownMarketplaces` entry point at a third-party GitHub repo), and `Read(~/**)` if you want Claude confined to your working directories. Keep one profile if you only need one and delete the other pair of files.
5. `claude/skills/review` assumes a code host reachable over MCP or comments pasted by hand; `/investigate` works on a bare path. Delete what you do not use.
6. Nothing else references a person: git identity and SSH keys are whatever the machine already has.

---

## Troubleshooting

**Shell looks wrong / plugins missing.** `~/.zshenv` must be a symlink into the repo. `setup.py check` reports it as `DRIFT`. Run `setup.py link`.

**`setup.py` says the pull failed.** Offline, or the clone has diverged from origin. It carried on with the local tree; reconcile with `git -C ~/dev/dotfiles pull --rebase` and run it again.

**`setup.py` asks for a profile.** First run on this machine, or `~/.local/state/dotfiles/profile` is gone. Pass `--profile work` or `--profile personal` once.

**`git pull` asks for the SSH passphrase every time.** The agent is not holding the key. Debian: `systemctl --user status ssh-agent` and `echo $SSH_AUTH_SOCK` (set by the graphical session; a terminal opened before logout/login after the first run does not have it). macOS: `ssh-add --apple-load-keychain`. Both: `ssh-add -l` lists what the agent holds.

**`compinit: insecure directories` on macOS.** `setup.py` fixes permissions; re-run it, or `compaudit | xargs chmod g-w,o-w`.

**Editor opens but no completion in Python or TypeScript.** The server binary is missing or not where `init.lua` looks: `ls ~/.local/bin/basedpyright-langserver` (Debian) or `ls /opt/homebrew/bin/basedpyright-langserver` (macOS); the `lsp` plugin logs to the editor's log (`Core: Open Log` in the command palette, `Ctrl+Shift+P`). `ls ~/.config/lite-xl/plugins` must list `lsp`; if not, run `setup.py` again and read the `lpm` output.

**`lpm` says "can't find addon".** Its repository cache is stale: `lpm update`, then `setup.py` again. `lpm` is told the plugin API level with `--mod-version`, never `--binary`, because asking the binary launches the editor.

**Claude edits when it should not, or refuses to edit.** Check the profile: `cat ~/.local/state/dotfiles/profile` and `readlink ~/.claude/settings.json`. `setup.py link --profile <work|personal>` switches; restart the Claude session afterwards.

**Fonts look wrong in the editor.** `fc-list | grep -i commitmono` (Linux) or Font Book (macOS) must list "CommitMono Nerd Font"; `init.lua` falls back to the bundled JetBrains Mono when the file is missing. Re-run `setup.py` / `brew install --cask font-commit-mono-nerd-font`.

**KDE shortcut does nothing.** Log out and in; `kglobalaccel` does not always pick up file changes. Check `~/.local/share/applications/dotfiles-editor.desktop` exists.

**Debian: Caps Lock is still Caps Lock, or both keys are swapped twice.** `systemctl status keyd` must be active and `/etc/keyd/default.conf` must hold the two lines; `sudo keyd monitor` shows the remapped events. Swapped twice means an old `Options=ctrl:swapcaps` is still in `~/.config/kxkbrc` from before `keyd`: run `setup.py` inside Plasma (it deletes the key) and log out and in.

**Ghostty not installed on Linux.** No community build for your Debian codename. Check <https://github.com/mkasberg/ghostty-ubuntu/releases>, bump `GHOSTTY_TAG` and `GHOSTTY_SHA256` in `setup.py` (the release API lists each asset's `digest`), or build from source. Konsole is bound to `Meta+Return` meanwhile.

**macOS: Caps Lock is still Caps Lock.** `launchctl list | grep capslock` should show the agent; `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.dotfiles.capslock.plist` loads it. Some keyboards need the remap re-applied after sleep; the agent runs at login only.
