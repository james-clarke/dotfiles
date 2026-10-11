# dotfiles

Set up git and an ssh key for GitHub, clone into `~/Developer`, run:

    ./setup.sh

Links configs into `$HOME`, installs nothing. Missing tools are printed with
the install command; install them and re-run. Re-run after any change to re-sync.

    ./setup.sh                      # default set: Mac = personal (opencode), Linux = work (claude)
    ./setup.sh bash git ssh         # just these
    ./setup.sh claude               # add claude to a machine later
    ./setup.sh all

Components: `bash git ssh vscode opencode claude system`.
`system` sets caps->ctrl, key repeat, sshd on, bash as login shell. Needs sudo.

## Linux third-party apt repos

Needed before `apt install` for code, claude-code, google-chrome-stable, tailscale.

    sudo apt install curl gpg && sudo install -d -m 0755 /etc/apt/keyrings
    sudo curl -fsSL -o /etc/apt/keyrings/claude-code.asc https://downloads.claude.ai/keys/claude-code.asc
    echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" | sudo tee /etc/apt/sources.list.d/claude-code.list
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null
    printf '%s\n' "Types: deb" "URIs: https://packages.microsoft.com/repos/code" "Suites: stable" "Components: main" "Architectures: amd64,arm64" "Signed-By: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/vscode.sources
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/google-chrome.gpg >/dev/null
    printf '%s\n' "Types: deb" "URIs: https://dl.google.com/linux/chrome/deb/" "Suites: stable" "Components: main" "Architectures: amd64" "Signed-By: /etc/apt/keyrings/google-chrome.gpg" | sudo tee /etc/apt/sources.list.d/google-chrome.sources
    . /etc/os-release
    curl -fsSL "https://pkgs.tailscale.com/stable/debian/$VERSION_CODENAME.noarmor.gpg" | sudo tee /etc/apt/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL "https://pkgs.tailscale.com/stable/debian/$VERSION_CODENAME.tailscale-keyring.list" | sed 's#/usr/share/keyrings/#/etc/apt/keyrings/#' | sudo tee /etc/apt/sources.list.d/tailscale.list
    sudo chmod 0644 /etc/apt/keyrings/* && sudo apt update

Mac: install Homebrew first from brew.sh.

## After the first run

Log out and back in.

Linux: `sudo tailscale up`, `ssh-copy-id macstation`.

Mac: open Tailscale and sign in, `ssh-copy-id debstation`.

opencode: `opencode auth login`, pick OpenRouter, paste key from openrouter.ai/keys.
