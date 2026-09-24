# dotfiles

My setup for Debian 13 with KDE, and for macOS. Zsh, Ghostty, Lite XL, git, Claude Code.

Set up git yourself first. The script does not do it: install git, set your name and
email, put an SSH key on GitHub. Then clone this repo and run the script from inside it.

## Run it

First time on a machine, pick a profile:

    python3 setup.py --profile work

`work` lets Claude Code edit files. `personal` keeps it read-only. The choice is saved
in `~/.local/state/dotfiles/profile`, so after that just:

    python3 setup.py

It pulls, re-links, upgrades, and re-applies whatever changed. Safe to run again.

Other commands:

    python3 setup.py link        symlinks only
    python3 setup.py check       verify the symlinks, exits 1 on drift
    python3 setup.py --dry-run   print every command, change nothing

## After the first run

Open a new terminal, or `exec zsh`, for the shell changes.

Log out and back in for the login shell, the session environment, and the caps lock
remap.

Then log into Claude Code and install the plugins:

    claude
    jq -r '.enabledPlugins | keys[]' ~/.claude/settings.json | xargs -n1 claude plugin install

Check it worked:

    python3 setup.py check
