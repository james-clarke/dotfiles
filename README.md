# dotfiles

Debian 13 KDE work box and a Mac. VS Code, Google Chrome, Konsole / Terminal,
bash, git, Claude Code, Tailscale + OpenSSH so the Mac can reach the Linux box.

Set up git and an SSH key for GitHub first, then clone this repo into `~/Developer` (where
code lives on both machines) and run:

    ./setup.sh

It installs the tools, symlinks the config below, and sets a few defaults. Safe to run again.
A real file already at a link target is moved to `<name>.bak`, or to
`<name>.bak.<timestamp>` if a `.bak` is already there, so no earlier backup is overwritten.

`./setup.sh --links-only` refreshes just the symlinks and installs nothing.

| repo file              | linked to                                                  |
| ---------------------- | ---------------------------------------------------------- |
| `bash/bashrc`          | `~/.bashrc` (env vars, history, prompt)                    |
| `bash/bash_profile`    | `~/.bash_profile` (sources `~/.bashrc`)                    |
| `git/config`, `ignore` | `~/.config/git/`                                           |
| `vscode/settings.json` | VS Code user settings                                      |
| `claude/settings.json` | `~/.claude/settings.json` (no auto memory, no co-author trailer, deny rules) |
| `ssh/config`           | `~/.ssh/config`, Mac only                                  |
| `macos/capslock.plist` | copied to `~/Library/LaunchAgents`, Mac only               |

Git reads both `~/.config/git/config` (this repo) and `~/.gitconfig`; keep your name and
email in `~/.gitconfig`, which wins on conflicts and stays out of the repo.

Defaults it sets: `~/Developer` created, Caps Lock and Left Ctrl swapped (keyd on Linux,
hidutil on the Mac), fast key repeat, bash as login shell, Chrome as default browser on
Linux, sshd enabled on Linux.

Chrome, not Chromium, on Linux: Debian's Chromium is built with browser sign-in patched
out, so signing in to a work Google profile silently fails after 2FA.

## After the first run

Log out and back in.

Linux: `sudo tailscale up`.

Mac: open Tailscale and sign in, then `ssh-copy-id debstation`. In VS Code, run
"Remote-SSH: Connect to Host..." and pick `debstation`.
