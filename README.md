# dotfiles

Set up git and ssh key for GitHub, clone into `~/Developer`, run:

    ./setup.sh

`./setup.sh --links-only` refreshes symlinks, installs nothing.


## After the first run

Log out and back in.

Linux: `sudo tailscale up`, `ssh-copy-id macstation`.

Mac: open Tailscale and sign in, `ssh-copy-id debstation`.

Both: `opencode auth login`, pick OpenRouter, paste key from openrouter.ai/keys.
