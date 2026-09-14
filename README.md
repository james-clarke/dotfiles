# dotfiles

A lean, keyboard-driven development environment for **Debian 13 + KDE Plasma 6** and **macOS**, built around **Emacs 30** (evil, vertico, eglot), a framework-free **zsh**, **Ghostty**, **mise**, git with SSH commit signing, and **Claude Code**. One command bootstraps a fresh machine on either OS; every file is symlinked from this repo so edits are versioned; CI proves the shell and the Emacs config load cleanly on both platforms.

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
11. [Toolchains: mise](#toolchains-mise)
12. [KDE](#kde)
13. [macOS specifics](#macos-specifics)
14. [Claude Code](#claude-code)
15. [Upgrading](#upgrading)
16. [Verification and CI](#verification-and-ci)
17. [Forking](#forking)
18. [Troubleshooting](#troubleshooting)

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
| Git | delta pager, SSH signing, `gh` credential helper | Signed commits out of the box; no GPG keyrings |
| Fonts | CommitMono Nerd Font | Ligatures + icons, installed by bootstrap |
| AI | Claude Code CLI | apt repo on Linux, Homebrew cask on macOS; runs in the terminal, Emacs auto-reverts edited files |
| Package managers | apt / Homebrew for everything with a package | Upgrades ride `apt upgrade` / `brew upgrade` |

Package counts stay small on purpose. Emacs pulls two dozen packages (plus their dependencies) from GNU ELPA, NonGNU ELPA and MELPA through the built-in `package.el`. There is no elpaca, straight, doom, or spacemacs layer.

---

## Install: Debian 13 + KDE

1. Install Debian 13 from the netinst with **KDE Plasma** and **standard system utilities**. Log in once so Plasma creates its config directories. A Wayland session is recommended (the default); the bootstrap picks the matching Emacs build.

2. Authenticate GitHub. Answer **n** to "Authenticate Git with your GitHub credentials" (the repo's git config already sets the helper).
   ```sh
   sudo apt install gh
   gh auth login -h github.com -p https -w -s admin:public_key
   ```

3. Run the bootstrap. It is idempotent; re-run it whenever you like.
   ```sh
   curl -fsSL https://raw.githubusercontent.com/james-clarke/dotfiles/master/bootstrap.sh | bash
   ```
   What it does, in order:
   - `apt install git gh curl`, then confirms `gh auth status`.
   - Clones this repo with submodules to `~/dev/dotfiles` (override with `DOTFILES_DIR`).
   - Runs `install.sh`: symlinks every config file into place, backing up anything that already exists as `*.bak.<timestamp>`, and removes links from earlier runs whose entry has since left the table (recorded in `~/.local/state/dotfiles/links`).
   - Prompts once for git name and email (use your GitHub noreply address), generates an ed25519 SSH key if none exists, registers it on GitHub for authentication and signing, and writes `allowed_signers`. These are the last prompts; everything after runs unattended.
   - Runs `os/linux.sh`:
     - installs everything in `os/apt-packages.txt`;
     - installs `emacs-pgtk` on a Wayland session, `emacs-gtk` on X11;
     - installs mise via its official installer;
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

1. Sign in to GitHub in a browser, then open Terminal.

2. Run the bootstrap.
   ```sh
   curl -fsSL https://raw.githubusercontent.com/james-clarke/dotfiles/master/bootstrap.sh | bash
   ```
   What it does, in order:
   - Installs Xcode Command Line Tools if missing (the script exits and asks you to re-run once the installer finishes).
   - Installs Homebrew if missing, then `git` and `gh`.
   - `gh auth login` in the browser if you are not logged in.
   - Clones the repo with submodules to `~/dev/dotfiles`.
   - Runs `install.sh` (symlinks, backups, stale-link pruning).
   - Prompts for git name and email, generates and registers the SSH key, writes `allowed_signers`. Last prompts; the rest runs unattended.
   - Runs `os/macos.sh`:
     - `brew bundle` against `os/Brewfile`: CLI tools, `emacs-plus@30` (native-comp), Ghostty, Claude Code, the Nerd Font;
     - copies `Emacs.app` to `/Applications` so Spotlight and the Dock can launch it;
     - starts the Emacs daemon via `brew services` (a launchd agent);
     - installs a LaunchAgent that remaps Caps Lock to Escape at every login (`hidutil`);
     - applies a curated set of `defaults write` (fast key repeat, no press-and-hold accents, no smart quotes, Finder shows extensions and hidden files, Dock autohide);
     - adds `AddKeysToAgent` / `UseKeychain` to `~/.ssh/config`;
     - fixes the Homebrew completion-directory permissions that otherwise trigger `compinit` warnings.
   - `mise install`. Git identity, SSH key generation and GitHub registration happened right after `install.sh`, same as Linux.

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

3. Verify that every symlink survived (Claude's `/model` command and some apps rewrite files; this catches it):
   ```sh
   ~/dev/dotfiles/install.sh check
   ```

4. Open Emacs: `Meta+E` on KDE, Spotlight → "Emacs" on macOS, or `e file` in any terminal. The first launch installs the Emacs packages (one to two minutes, once). Native compilation runs in the background afterwards; ignore the `*Async-native-compile-log*` buffer.

5. Test commit signing anywhere:
   ```sh
   git commit --allow-empty -m "test: signing"
   git log --show-signature -1     # expect "Good signature"
   ```

6. Linux only, if bootstrap ran outside a Plasma session: run `~/dev/dotfiles/kde/apply.sh` now, then log out and in.

---

## Repository layout

```
bootstrap.sh            one-shot installer; OS-independent steps, dispatches to os/
install.sh              symlinks repo files into $HOME; `install.sh check` verifies
os/
  linux.sh              Debian 13 + KDE packages, Emacs daemon, Ghostty, Claude Code, fonts
  macos.sh              Homebrew bundle, Emacs daemon, keyboard remap, defaults
  apt-packages.txt      flat apt list
  Brewfile              formulae, taps, casks
  macos/defaults.sh     curated `defaults write`
  macos/capslock.plist  LaunchAgent: Caps Lock -> Escape
emacs/
  early-init.el         GC and frame settings applied before the GUI exists
  init.el               the whole Emacs config, one file
zsh/
  home.zshenv           the only file in $HOME; sets ZDOTDIR and sources the real .zshenv
  .zshenv               env for every zsh: XDG dirs, PATH, EDITOR
  .zprofile             login shells: Homebrew PATH order on macOS
  .zshrc                interactive: history, completion, prompt, plugins, tools, widgets
  plugins/              fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting (submodules)
ghostty/config          shared terminal config
config/
  git/config            git defaults; includes config.local for identity
  git/ignore            global gitignore
  mise/config.toml      global toolchain
kde/
  apply.sh              Plasma settings via kwriteconfig6 (keyboard, fonts, shortcuts)
  env.sh                Plasma session env (PATH, EDITOR) for GUI apps
  dotfiles-emacs.desktop hidden launcher bound to Meta+E
claude/
  CLAUDE.md             global rules for Claude Code
  settings.json         permissions, sandbox, plugins, statusline
  statusline.sh         model / effort / project / branch / context / cost line
  output-styles/        "minimal" output style
  skills/flow/          /flow: ticket dev, PR review, investigate pipelines
.github/workflows/ci.yml  Linux (Debian container) + macOS checks
```

### Where things land

| Repo file | Symlink target |
|---|---|
| `zsh/home.zshenv` | `~/.zshenv` |
| `zsh/` | `~/.config/zsh/` |
| `emacs/early-init.el`, `emacs/init.el` | `~/.config/emacs/` (packages, `custom.el`, `eln-cache` live there too, untracked) |
| `ghostty/config` | `~/.config/ghostty/config` |
| `config/git/*` | `~/.config/git/` |
| `config/mise/config.toml` | `~/.config/mise/config.toml` |
| `claude/*` | `~/.claude/` |
| `kde/env.sh` (Linux) | `~/.config/plasma-workspace/env/dotfiles.sh` |
| `kde/dotfiles-emacs.desktop` (Linux) | `~/.local/share/applications/` |

Files that must not be symlinks (Plasma rewrites its rc files atomically, launchd wants a real plist) are written by `kde/apply.sh` and `os/macos.sh` instead.

---

## How the pieces fit

**Editor everywhere.** `EDITOR` and `VISUAL` are `emacsclient -t` in shells (a terminal frame inside your current terminal, fast, closes with `C-x #` or `:q`), and `emacsclient -c` for GUI sessions (KDE via `kde/env.sh`; macOS apps inherit from launchd). `ALTERNATE_EDITOR` is the empty string, which tells emacsclient to start the daemon if it is not running. Git commit messages, `crontab -e`, `gh pr create` all open in Emacs.

**One PATH story.** `~/.local/bin` first, then mise shims, then the system. Shells get it from `.zshenv`/`.zprofile`. GUI apps get it from the Plasma session env on Linux and from `exec-path-from-shell` on macOS. Emacs additionally prepends both directories to `exec-path` itself, so eglot finds `basedpyright` and `typescript-language-server` even when the daemon was started by systemd or launchd with a minimal environment.

**Keyboard.** Caps Lock is Escape on both OSes (KDE `kxkbrc`, macOS `hidutil`). Key repeat is fast on both. `Meta+E` (KDE) opens an Emacs frame, `Meta+Return` a terminal, `Meta+D` KRunner. On macOS, Option is Meta in Emacs and Ghostty; Command stays Command.

**Package managers own upgrades.** apt and Homebrew install Emacs, Ghostty, Claude Code, CLI tools. mise installs language toolchains and LSP servers. Emacs `package.el` installs Emacs packages. Nothing is curl-piped except mise's installer on Linux and Homebrew's installer on macOS.

---

## Emacs

### Startup and daemon

`early-init.el` raises the GC threshold and disables `file-name-handler-alist` during startup, then restores sane values; it also turns off the menu bar, tool bar and scroll bars before the first frame exists. `gcmh` manages GC after startup (collects when idle, not while you type).

The daemon runs under `systemctl --user` (Linux; the unit ships with Debian's `emacs-common`) or `brew services` (macOS). Frames connect in about 100 ms. If the daemon dies, any `emacsclient` call restarts it because `ALTERNATE_EDITOR` is empty.

```sh
systemctl --user status emacs          # Linux
brew services info emacs-plus@30       # macOS
emacsclient -e '(kill-emacs)'          # stop the daemon cleanly (either OS)
```

### Packages

Built-in and used: `use-package`, `eglot`, `treesit`, `which-key`, `editorconfig`, `project`, `flymake`, `repeat-mode`, `pixel-scroll-precision-mode`, `modus-themes`, `savehist`, `recentf`, `save-place`, `winner`, `dired`, `so-long`, `xterm-mouse-mode`.

Installed from ELPA/MELPA: `gcmh`, `evil`, `evil-collection`, `evil-surround`, `vertico`, `orderless`, `marginalia`, `consult`, `consult-eglot`, `embark`, `embark-consult`, `corfu`, `corfu-terminal`, `cape`, `treesit-auto`, `apheleia`, `envrc`, `markdown-mode`, `magit`, `diff-hl`, `eat`, `wgrep`, `mood-line`, `ligature`, and on macOS only `exec-path-from-shell`.

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
| `SPC b b` / `b d` / `b n` / `b p` / `b r` / `b s` | buffers / kill / next / prev / revert / scratch |
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
| `SPC t t` / `t l` / `t w` / `t f` | toggle theme / line numbers / word wrap / fullscreen |
| `SPC q q` / `q f` | quit Emacs / close frame |

Non-leader: `C-s` consult-line, `C-.` embark-act, `C-;` embark-dwim, `C-x g` magit, `C-j` / `C-k` move in vertico and corfu popups, `<` narrows a consult list (e.g. `SPC ,` then `< b` for buffers only, `< f` for files), `TAB` completes or indents, `M-x` still works.

### Languages

`treesit-auto` maps file types to tree-sitter modes and offers to install a grammar the first time you open a language (grammars compile with the system `cc`, which apt and Xcode CLT provide). eglot starts automatically in Python, JavaScript/TypeScript, Rust, Go, C/C++, Bash and Ruby buffers when a server is on PATH. `basedpyright` and `typescript-language-server` come from mise. Add others per project with `mise use`.

apheleia formats on save with whatever formatter it knows for the mode (`black`/`ruff`, `prettier`, `gofmt`, `rustfmt`, `shfmt`...) if that binary is on PATH; missing formatter means no-op, never an error. envrc loads `.envrc` per buffer so project-local tools win.

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

Commits and tags are signed with your SSH key. `gpg.format = ssh`, `allowedSignersFile` points at `~/.config/git/allowed_signers`, which bootstrap writes from your email and public key. GitHub shows "Verified" because bootstrap registered the same key as a signing key.

Identity lives in `~/.config/git/config.local` (created by `install.sh`, filled by bootstrap, never committed). Put machine-specific credential helpers or overrides there too.

`core.editor` is not set; git follows `VISUAL`/`EDITOR`, so it opens a terminal frame in shells and a GUI frame from GUI apps.

---

## Toolchains: mise

`config/mise/config.toml` is the global toolchain: `node` (LTS), `uv`, `basedpyright`, `typescript-language-server`, `typescript`. Projects override with their own `.mise.toml` or `.python-version`. `mise activate zsh` runs in interactive shells; GUI apps and the Emacs daemon use the shims directory instead, which is on PATH everywhere.

```sh
mise use -g go@latest        # add a global tool
mise use python@3.13         # per project
mise upgrade                 # bump everything
```

---

## KDE

`kde/apply.sh` writes only the keys this repo owns, via `kwriteconfig6`, and leaves the rest of Plasma's config alone:

- `kxkbrc`: `caps:swapescape`;
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
- **Caps Lock → Escape** uses `hidutil` in a LaunchAgent (`com.dotfiles.capslock`), re-applied at each login because the mapping does not persist across reboots.
- **`defaults`** applied by `os/macos/defaults.sh`; edit the list before running if you disagree with any. Dock and Finder restart automatically; keyboard settings apply after logout.
- **SSH** uses the Keychain for the key passphrase (`UseKeychain yes`).
- **No tiling manager** is installed. Sequoia's built-in tiling (`Fn+Control+arrows`) covers halves; add AeroSpace or Rectangle to the Brewfile if you want more.
- **Claude Code** is the `claude-code` Homebrew cask, so `brew upgrade` updates it.

---

## Claude Code

`claude/settings.json` is symlinked to `~/.claude/settings.json`:

- **Permissions**: read-only git and `gh` commands are pre-allowed; `git push` is denied (Claude prints the command, you run it). `defaultMode` is `auto`.
- **Sandbox**: on, with network egress limited to GitHub, npm and PyPI; the private SSH key is hidden; the `gh` token is masked and injected only for GitHub hosts. Bubblewrap (Linux) or Seatbelt (macOS) provides the isolation.
- **Plugins**: `typescript-lsp`, `pyright-lsp`, `remember`, `caveman`. Install them once with the `jq | xargs` one-liner in [After bootstrap](#after-bootstrap).
- **Statusline**: `claude/statusline.sh` shows exceptions only: model, `project:branch`, effort when it is not `high`, context usage with a hand-off warning at 25 %, and the 5h/7d rate-limit windows once they pass 50 %. One `jq` call, plus `git` for the branch.
- **Output style** `minimal`: answer first, no preamble, no recap.

`claude/CLAUDE.md` holds the global working rules (small diffs, plan mode for wide changes, no unsolicited tests, conventional commits, model tiering for subagents, context hygiene). `claude/skills/flow` is a `/flow` skill with ticket-development, PR-review, re-review and investigate pipelines that use adversarial multi-agent review; it is framework-agnostic and reads each repo's `AGENTS.md` for the rules that matter there.

Claude runs in a terminal, not inside Emacs. Emacs has `global-auto-revert-mode`, so files Claude edits update in your buffers immediately; magit shows the diff.

---

## Upgrading

| What | Command |
|---|---|
| Everything system-level, Linux | `sudo apt update && sudo apt upgrade` (Emacs, Ghostty stays pinned, Claude Code, CLI tools) |
| Everything system-level, macOS | `brew update && brew upgrade && brew bundle --file ~/dev/dotfiles/os/Brewfile` |
| Ghostty on Linux | bump `GHOSTTY_TAG` in `os/linux.sh`, remove the package, re-run `os/linux.sh` |
| Emacs packages | `M-x package-upgrade-all`, then `M-x package-autoremove` |
| Toolchains and LSP servers | `mise upgrade` |
| zsh plugins | `git -C ~/dev/dotfiles submodule update --remote` |
| The dotfiles themselves | `git -C ~/dev/dotfiles pull && ~/dev/dotfiles/install.sh check` |
| KDE settings after editing `kde/apply.sh` | re-run it, log out and in |
| macOS defaults after editing | re-run `os/macos/defaults.sh` |

Re-running `bootstrap.sh` is always safe; every step checks before it acts.

---

## Verification and CI

`.github/workflows/ci.yml` runs on every push:

- **Linux job** in a `debian:trixie` container (the exact target): `shellcheck` on every script, `zsh -n` on every zsh file, `jq` on `settings.json`, `git config` parse, then a full `install.sh` into a fresh `HOME`, `install.sh check`, an interactive zsh start that must print nothing, and finally Emacs 30 loads `early-init.el` + `init.el` in batch mode, installing every package from the real archives (ELPA cache keyed on `init.el`), and byte-compiles both files.
- **macOS job**: shellcheck, `zsh -n`, `plutil -lint` on the LaunchAgent, `install.sh` + `check` into a fresh `HOME`, interactive zsh start, then the same Emacs batch load and byte-compile with Homebrew's `emacs` formula, so the `darwin` branch of `init.el` runs for real. The Brewfile itself is validated by use.

Locally: `~/dev/dotfiles/install.sh check` after anything that might have replaced a symlink.

---

## Forking

1. Fork on GitHub, then in `bootstrap.sh` change `REPO_URL`, or run it with `DOTFILES_REPO=https://github.com/you/dotfiles`.
2. Edit `os/apt-packages.txt` and `os/Brewfile` to taste.
3. Adjust `kde/apply.sh` and `os/macos/defaults.sh`; both are lists of individual settings, remove lines you do not want.
4. `claude/settings.json`: change or drop `model`, plugins, allowed network domains.
5. Nothing else references a person: git identity is prompted, SSH keys are generated, the `hostname` names the GitHub key.

---

## Troubleshooting

**Shell looks wrong / plugins missing.** `~/.zshenv` must be a symlink into the repo. `install.sh check` reports it as `DRIFT`. Re-run `install.sh`.

**`compinit: insecure directories` on macOS.** `os/macos.sh` fixes permissions; re-run it, or `compaudit | xargs chmod g-w,o-w`.

**`emacsclient: can't find socket`.** The daemon is not running and `ALTERNATE_EDITOR` is not empty in this environment. `systemctl --user restart emacs` (Linux) or `brew services restart emacs-plus@30` (macOS), or just `emacsclient -a '' -c`.

**Emacs starts but packages are missing.** First launch needs network to ELPA/MELPA. `M-x package-refresh-contents`, then `M-x package-install-selected-packages`. Corporate proxies: set `url-proxy-services` in `custom.el`.

**eglot: "no server".** The server binary is not on the daemon's PATH. `mise ls` shows what is installed; `mise install` if needed; `emacsclient -e '(getenv "PATH")'` shows what the daemon sees. Restart the daemon after installing a new tool.

**Fonts look wrong in Emacs.** `fc-list | grep -i commitmono` (Linux) or Font Book (macOS) must list "CommitMono Nerd Font". Re-run `os/linux.sh` / `brew install --cask font-commit-mono-nerd-font`.

**KDE shortcut does nothing.** Log out and in; `kglobalaccel` does not always pick up file changes. Check `~/.local/share/applications/dotfiles-emacs.desktop` exists.

**Ghostty not installed on Linux.** No community build for your Debian codename. Check <https://github.com/mkasberg/ghostty-ubuntu/releases>, bump `GHOSTTY_TAG` and the `GHOSTTY_SHA256_*` values in `os/linux.sh` (the release API lists each asset's `digest`), or build from source. Konsole is bound to `Meta+Return` meanwhile.

**Claude Code sandbox cannot reach a host.** Add the domain to `sandbox.network.allowedDomains` in `claude/settings.json` or run `/sandbox` inside Claude.

**macOS: Caps Lock is still Caps Lock.** `launchctl list | grep capslock` should show the agent; `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.dotfiles.capslock.plist` loads it. Some keyboards need the remap re-applied after sleep; the agent runs at login only.
