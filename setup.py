#!/usr/bin/env python3
"""Set up a Debian 13 + KDE or macOS machine from this repo, and keep it in sync.

    python3 setup.py --profile work      first run: install, link, configure
    python3 setup.py                     later: pull, re-link, upgrade, re-apply what changed
    python3 setup.py link                symlinks only
    python3 setup.py check               verify every symlink; exit 1 on drift
    python3 setup.py --dry-run           print every command, run nothing

Assumes git is already set up: you cloned this repo, so the SSH key and the git
identity are yours to configure, not this script's.

Profiles: `work` (Claude Code may edit, prompts kept) and `personal` (read-only Claude).
The profile is remembered in ~/.local/state/dotfiles/profile after the first run.
Standard library only; runs on the Python 3.9 that macOS Command Line Tools ship.
"""

from __future__ import annotations

import argparse
import filecmp
import hashlib
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parent
HOME = Path.home()
BIN = HOME / ".local/bin"
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "dotfiles"
OS = platform.system()  # "Linux" or "Darwin"
PROFILES = ("work", "personal")
DRY = False

GHOSTTY_TAG = "1.3.1-0-ppa2"
GHOSTTY_SHA256 = {
    "amd64": "9fda8e418d7a7f58149ba3ba823a255d6b80f8bb5431b3bd7e912ff597715b2e",
    "arm64": "73f384e62c419d7a7809d686bf579fea5e23f52742b34f70c74d6adf0e72f8ab",
}
NERD_FONTS_TAG = "v3.5.1"
NERD_FONTS_SHA256 = "9f26650f142d69b33522b9b2c67e3f8ca21eafbde5e143d842dedbf2bb829bf5"  # CommitMono.zip
CLAUDE_KEY_FPR = "31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"
CHROME_KEY_FPR = "EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796"
LITE_XL_TAG = "v2.1.8"
LITE_XL_MOD_VERSION = "3"  # plugin API level of that release; lpm filters addons by it
LITE_XL_SHA256 = {  # release asset digests, https://api.github.com/repos/lite-xl/lite-xl/releases/tags/<tag>
    "linux-x86_64": "38fed20cd27057049f598dd80671d8aa04c1f74684d99bd246ed2676b758bfec",
    "macos-arm64": "1b8ad02ea575d08d6557daff035d4ac59c069254dd85d01f7bdac839cfdd66e3",
}
LPM_TAG = "v1.4.9"
LPM_SHA256 = {
    "x86_64-linux": "872c464aff8c9191e0e07baf2874264eaeb5da1991fdd15557270f6e8582ad6e",
    "aarch64-darwin": "0dff67c9220052d6dbf80dffe5fe61d40187d1e09c7d64617a460ed61aae6352",
}

KEYD_CONF = """[ids]
*

[main]
capslock = leftcontrol
leftcontrol = capslock
"""

# kwriteconfig6 writes: (file, "group/subgroup", key, value); value None deletes the key.
KDE_KEYS = [
    ("kxkbrc", "Layout", "Options", None),  # keyd does the caps/ctrl swap now
    ("kxkbrc", "Layout", "ResetOldOptions", "true"),
    ("kcminputrc", "Keyboard", "RepeatDelay", "250"),
    ("kcminputrc", "Keyboard", "RepeatRate", "40"),
    ("kdeglobals", "General", "fixed", "CommitMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"),
    ("mimeapps.list", "Default Applications", "text/plain", "dotfiles-editor.desktop"),
    ("kglobalshortcutsrc", "services/dotfiles-editor.desktop", "_launch", "Meta+E"),
    ("kglobalshortcutsrc", "services/org.kde.krunner.desktop", "_launch", "Meta+D"),
    ("kglobalshortcutsrc", "kwin", "Show Desktop", "none,Meta+D,Peek at Desktop"),
    ("kglobalshortcutsrc", "kwin", "Window Close", "Meta+Shift+Q,Alt+F4,Close Window"),
    ("kglobalshortcutsrc", "kwin", "Window to Previous Screen", "none,Meta+Shift+Left,Move Window to Previous Screen"),
    ("kglobalshortcutsrc", "kwin", "Window to Next Screen", "none,Meta+Shift+Right,Move Window to Next Screen"),
    ("kglobalshortcutsrc", "kwin", "Switch Window Left", "Meta+Left,Meta+Alt+Left,Switch to Window to the Left"),
    ("kglobalshortcutsrc", "kwin", "Switch Window Down", "Meta+Down,Meta+Alt+Down,Switch to Window Below"),
    ("kglobalshortcutsrc", "kwin", "Switch Window Up", "Meta+Up,Meta+Alt+Up,Switch to Window Above"),
    ("kglobalshortcutsrc", "kwin", "Switch Window Right", "Meta+Right,Meta+Alt+Right,Switch to Window to the Right"),
    ("kglobalshortcutsrc", "kwin", "Window Quick Tile Left", "Meta+Shift+Left,Meta+Left,Quick Tile Window to the Left"),
    ("kglobalshortcutsrc", "kwin", "Window Quick Tile Bottom", "Meta+Shift+Down,Meta+Down,Quick Tile Window to the Bottom"),
    ("kglobalshortcutsrc", "kwin", "Window Quick Tile Top", "Meta+Shift+Up,Meta+Up,Quick Tile Window to the Top"),
    ("kglobalshortcutsrc", "kwin", "Window Quick Tile Right", "Meta+Shift+Right,Meta+Right,Quick Tile Window to the Right"),
    ("kglobalshortcutsrc", "kwin", "Window Maximize", "Meta+F\tMeta+PgUp,Meta+PgUp,Maximize Window"),
    ("kglobalshortcutsrc", "kwin", "Window Fullscreen", "Meta+Shift+F,,Make Window Fullscreen"),
]

# arguments to `defaults`, one call per row. Keyboard, accessibility and login rows apply after logout.
MACOS_DEFAULTS = [
    ("write", "-g", "KeyRepeat", "-int", "1"),
    ("write", "-g", "InitialKeyRepeat", "-int", "10"),
    ("write", "-g", "ApplePressAndHoldEnabled", "-bool", "false"),
    ("write", "-g", "NSAutomaticQuoteSubstitutionEnabled", "-bool", "false"),
    ("write", "-g", "NSAutomaticDashSubstitutionEnabled", "-bool", "false"),
    ("write", "-g", "NSAutomaticSpellingCorrectionEnabled", "-bool", "false"),
    ("write", "-g", "NSAutomaticCapitalizationEnabled", "-bool", "false"),
    ("write", "-g", "AppleShowAllExtensions", "-bool", "true"),
    ("write", "-g", "NSQuitAlwaysKeepsWindows", "-bool", "false"),  # no window restore at login
    ("write", "com.apple.universalaccess", "reduceMotion", "-bool", "true"),
    ("write", "com.apple.universalaccess", "reduceTransparency", "-bool", "true"),
    ("write", "com.apple.finder", "AppleShowAllFiles", "-bool", "true"),
    ("write", "com.apple.finder", "ShowPathbar", "-bool", "true"),
    ("write", "com.apple.finder", "ShowStatusBar", "-bool", "true"),
    ("write", "com.apple.finder", "FXEnableExtensionChangeWarning", "-bool", "false"),
    ("write", "com.apple.desktopservices", "DSDontWriteNetworkStores", "-bool", "true"),
    ("write", "com.apple.desktopservices", "DSDontWriteUSBStores", "-bool", "true"),
    ("write", "com.apple.dock", "autohide", "-bool", "true"),
    ("write", "com.apple.dock", "show-recents", "-bool", "false"),
    ("write", "com.apple.dock", "wvous-tl-corner", "-int", "0"),  # hot corners off
    ("write", "com.apple.dock", "wvous-tr-corner", "-int", "0"),
    ("write", "com.apple.dock", "wvous-bl-corner", "-int", "0"),
    ("write", "com.apple.dock", "wvous-br-corner", "-int", "0"),
    ("-currentHost", "write", "com.apple.coreservices.useractivityd", "ActivityAdvertisingAllowed", "-bool", "false"),
    ("-currentHost", "write", "com.apple.coreservices.useractivityd", "ActivityReceivingAllowed", "-bool", "false"),
]


# ---------------------------------------------------------------- helpers


def step(name):
    print(f"\n\033[1;34m== {name}\033[0m")


def say(tag, what):
    print(f"{tag:<10} {what}")


def run(*cmd, sudo=False, check=True, env=None, stdin=None, quiet=False):
    """Run a command that changes something. Printed instead of run under --dry-run."""
    cmd = [str(c) for c in cmd]
    if sudo:
        cmd = ["sudo", *cmd]
    if DRY:
        say("would run", " ".join(cmd))
        return subprocess.CompletedProcess(cmd, 0, "", "")
    return subprocess.run(
        cmd,
        check=check,
        env=env,
        input=stdin,
        text=True,
        stdout=subprocess.DEVNULL if quiet else None,
    )


def query(*cmd, env=None):
    """Run a read-only command and return its stdout; "" when it is missing, fails or hangs."""
    cmd = [str(c) for c in cmd]
    try:
        return subprocess.run(
            cmd, capture_output=True, text=True, env=env, check=False, timeout=30
        ).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def have(name, env=None):
    return shutil.which(name, path=(env or os.environ).get("PATH")) is not None


def read_list(path):
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]


def read_state(name):
    try:
        return (STATE / name).read_text().strip()
    except OSError:
        return ""


def write_state(name, text):
    if DRY:
        return
    STATE.mkdir(parents=True, exist_ok=True)
    (STATE / name).write_text(text + "\n")


def same_content(path, text):
    try:
        return path.read_text() == text
    except OSError:
        return False


def write_root_file(path, text):
    """Write a root-owned file via sudo only when its content differs. True when it wrote."""
    if same_content(path, text):
        say("ok", path)
        return False
    run("install", "-d", "-m", "0755", path.parent, sudo=True)
    run("tee", path, sudo=True, stdin=text, quiet=True)
    say("would write" if DRY else "wrote", path)
    return True


def download(url, dest):
    say("fetching", url)
    if DRY:
        return
    with urllib.request.urlopen(url, timeout=60) as resp, open(dest, "wb") as out:
        shutil.copyfileobj(resp, out)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def fetch_verified(url, dest, expected):
    download(url, dest)
    if not DRY and sha256(dest) != expected:
        sys.exit(f"checksum mismatch: {url}")


def shim(target, link):
    """Force a symlink link -> target (PATH shims under ~/.local/bin)."""
    if link.is_symlink() and os.readlink(link) == str(target):
        return
    if DRY:
        say("would link", f"{link} -> {target}")
        return
    link.parent.mkdir(parents=True, exist_ok=True)
    if link.is_symlink() or link.exists():
        link.unlink()
    link.symlink_to(target)
    say("linked", f"{link} -> {target}")


def digest(obj):
    return hashlib.sha256(repr(obj).encode()).hexdigest()


# ---------------------------------------------------------------- profile + links


def resolve_profile(flag):
    saved = read_state("profile")
    if flag and saved and flag != saved:
        say("profile", f"switching {saved} -> {flag}")
    profile = flag or saved
    if profile not in PROFILES:
        sys.exit("first run on this machine: pass --profile work or --profile personal")
    if profile != saved:
        write_state("profile", profile)
    return profile


def link_table(profile):
    pairs = {
        f"claude/settings.{profile}.json": ".claude/settings.json",
        f"claude/CLAUDE.{profile}.md": ".claude/CLAUDE.md",
        "claude/common.md": ".claude/common.md",
        "claude/statusline.sh": ".claude/statusline.sh",
        "claude/skills": ".claude/skills",
        "config/git/config": ".config/git/config",
        "config/git/ignore": ".config/git/ignore",
        "lite-xl/init.lua": ".config/lite-xl/init.lua",
        "ghostty/config": ".config/ghostty/config",
        "zsh": ".config/zsh",
        "zsh/home.zshenv": ".zshenv",
    }
    if OS == "Linux":
        pairs["kde/env.sh"] = ".config/plasma-workspace/env/dotfiles.sh"
        pairs["kde/dotfiles-editor.desktop"] = ".local/share/applications/dotfiles-editor.desktop"
    return {REPO / src: HOME / dst for src, dst in pairs.items()}


def link_all(table):
    for src, dst in table.items():
        if dst.is_symlink():
            if os.readlink(dst) == str(src):
                say("ok", dst)
                continue
            if not DRY:
                dst.unlink()
        elif dst.exists():
            bak = dst.with_name(dst.name + ".bak")
            if bak.exists() or bak.is_symlink():
                bak = dst.with_name(f"{dst.name}.bak.{int(time.time())}")
            if not DRY:
                dst.rename(bak)
            say("moved", f"{dst} -> {bak}")
        if not DRY:
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.symlink_to(src)
        say("linked", dst)
    current = {str(dst) for dst in table.values()}
    for old in read_state("links").splitlines():
        old = Path(old)
        # Prune only links under this HOME that point into this repo: a manifest written from
        # another HOME (CI, a test run) must never touch the real one.
        if str(old) in current or not old.is_symlink() or not str(old).startswith(str(HOME) + os.sep):
            continue
        if os.readlink(old).startswith(str(REPO) + os.sep):
            if not DRY:
                old.unlink()
            say("pruned", old)
    write_state("links", "\n".join(sorted(current)))


def check_all(table):
    ok = True
    for src, dst in table.items():
        if dst.is_symlink() and os.readlink(dst) == str(src):
            say("ok", dst)
        else:
            say("DRIFT", dst)
            ok = False
    return ok


# ---------------------------------------------------------------- editor


def lite_xl(tmp):
    """Lite XL from the pinned GitHub release, lpm, and the plugin list. Portable install, no root."""
    step("lite-xl")
    machine = platform.machine()
    if OS == "Linux":
        build, lpm_build = f"linux-{machine}", f"{machine}-linux"
        app = HOME / ".local/share/lite-xl"
        binary = app / "lite-xl"
    else:
        build, lpm_build = f"macos-{machine}", ("aarch64-darwin" if machine == "arm64" else "")
        app = Path("/Applications/Lite XL.app")
        binary = app / "Contents/MacOS/lite-xl"
    if build not in LITE_XL_SHA256 or lpm_build not in LPM_SHA256:
        say("skip", f"no pinned lite-xl build for {OS}/{machine}")
        return

    if read_state("lite-xl") == LITE_XL_TAG and binary.exists():
        say("ok", f"lite-xl {LITE_XL_TAG}")
    elif OS == "Linux":
        archive = tmp / "lite-xl.tar.gz"
        fetch_verified(
            f"https://github.com/lite-xl/lite-xl/releases/download/{LITE_XL_TAG}/lite-xl-{LITE_XL_TAG}-{build}-portable.tar.gz",
            archive, LITE_XL_SHA256[build],
        )
        if not DRY:
            shutil.rmtree(app, ignore_errors=True)
            app.parent.mkdir(parents=True, exist_ok=True)
            with tarfile.open(archive) as tar:  # top-level dir inside is lite-xl/
                tar.extractall(app.parent, **({"filter": "data"} if hasattr(tarfile, "data_filter") else {}))
        say("would install" if DRY else "installed", app)
        write_state("lite-xl", LITE_XL_TAG)
    else:
        dmg = tmp / "lite-xl.dmg"
        fetch_verified(
            f"https://github.com/lite-xl/lite-xl/releases/download/{LITE_XL_TAG}/lite-xl-{LITE_XL_TAG}-{build}.dmg",
            dmg, LITE_XL_SHA256[build],
        )
        mount = tmp / "mnt"
        if not DRY:
            mount.mkdir()
        run("hdiutil", "attach", "-nobrowse", "-quiet", "-mountpoint", mount, dmg)
        run("rm", "-rf", app)
        run("cp", "-R", mount / app.name, app)
        run("hdiutil", "detach", "-quiet", mount)
        run("xattr", "-dr", "com.apple.quarantine", app, check=False)  # checksum verified above; skip the right-click dance
        say("would install" if DRY else "installed", app)
        write_state("lite-xl", LITE_XL_TAG)
    shim(binary, BIN / "lite-xl")

    lpm = BIN / "lpm"
    if read_state("lpm") == LPM_TAG and lpm.exists():
        say("ok", f"lpm {LPM_TAG}")
    else:
        staged = tmp / "lpm"
        fetch_verified(
            f"https://github.com/lite-xl/lite-xl-plugin-manager/releases/download/{LPM_TAG}/lpm.{lpm_build}",
            staged, LPM_SHA256[lpm_build],
        )
        if not DRY:
            staged.chmod(0o755)
            BIN.mkdir(parents=True, exist_ok=True)
            shutil.move(str(staged), str(lpm))
        write_state("lpm", LPM_TAG)
    plugins = read_list(REPO / "os/lite-xl-plugins.txt")
    mod = f"--mod-version={LITE_XL_MOD_VERSION}"  # never --binary: lpm would launch the editor to ask
    run(lpm, "install", "--assume-yes", mod, *plugins)
    run(lpm, "upgrade", "--assume-yes", mod)


# ---------------------------------------------------------------- linux


def linux_packages():
    step("apt")
    run("apt-get", "update", "-q", sudo=True)
    run("apt-get", "install", "-y", "-q", *read_list(REPO / "os/apt-packages.txt"), sudo=True)
    run("apt-get", "upgrade", "-y", "-q", sudo=True)
    for tool, debian_name in (("bat", "batcat"), ("fd", "fdfind")):
        shim(Path("/usr/bin") / debian_name, BIN / tool)

    step("npm tools")  # language servers apt does not carry; under ~/.local, no sudo
    env = dict(os.environ, npm_config_prefix=str(HOME / ".local"))
    run("npm", "install", "-g", *read_list(REPO / "os/npm-packages.txt"), env=env)


def linux_font(tmp):
    step("font")
    fonts = HOME / ".local/share/fonts/CommitMonoNerdFont"
    if fonts.is_dir() and read_state("font") in ("", NERD_FONTS_TAG):  # "": installed before the state key existed
        say("ok", f"nerd-fonts {NERD_FONTS_TAG}")
        write_state("font", NERD_FONTS_TAG)
        return
    archive = tmp / "font.zip"
    fetch_verified(
        f"https://github.com/ryanoasis/nerd-fonts/releases/download/{NERD_FONTS_TAG}/CommitMono.zip",
        archive, NERD_FONTS_SHA256,
    )
    if DRY:
        return
    shutil.rmtree(fonts, ignore_errors=True)
    fonts.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as z:
        for member in z.namelist():
            if member not in ("LICENSE", "README.md"):
                z.extract(member, fonts)
    run("fc-cache", "-f")
    write_state("font", NERD_FONTS_TAG)


def linux_ghostty(tmp):
    step("ghostty")
    upstream, ppa = GHOSTTY_TAG.rsplit("-", 1)
    want = f"{upstream}.{ppa}"
    if query("dpkg-query", "-W", "-f=${Version}", "ghostty") == want:
        say("ok", f"ghostty {want}")
        return
    codename = query("sed", "-n", "s/^VERSION_CODENAME=//p", "/etc/os-release")
    arch = query("dpkg", "--print-architecture")
    expected = GHOSTTY_SHA256.get(arch)
    if codename != "trixie" or not expected:
        say("skip", f"no verified ghostty build for {codename}/{arch}; konsole stays the terminal")
        return
    deb = tmp / f"ghostty_{want}_{arch}_{codename}.deb"
    try:
        download(f"https://github.com/mkasberg/ghostty-ubuntu/releases/download/{GHOSTTY_TAG}/{deb.name}", deb)
    except (urllib.error.URLError, OSError) as e:
        say("skip", f"ghostty download failed ({e}); konsole stays the terminal")
        return
    if not DRY and sha256(deb) != expected:
        sys.exit("ghostty checksum mismatch")
    run("apt-get", "install", "-y", "-q", deb, sudo=True)


def linux_keyd():
    step("keyd: swap caps lock and left ctrl")
    changed = write_root_file(Path("/etc/keyd/default.conf"), KEYD_CONF)
    run("systemctl", "enable", "--now", "keyd", sudo=True)
    # Debian renames the binary to keyd.rvaiya, so `keyd reload` is not portable, and the unit
    # has no ExecReload; a restart is what picks up a changed config on an already-running keyd.
    if changed:
        run("systemctl", "restart", "keyd", sudo=True, check=False)


def linux_claude_code(tmp):
    step("claude code")
    if have("claude"):
        say("ok", "claude")
        return
    key = tmp / "claude-code.asc"
    download("https://downloads.claude.ai/keys/claude-code.asc", key)
    if not DRY and f":{CLAUDE_KEY_FPR}:" not in query("gpg", "--show-keys", "--with-colons", key):
        sys.exit("claude-code.asc fingerprint mismatch")
    run("install", "-D", "-m", "0644", key, "/etc/apt/keyrings/claude-code.asc", sudo=True)
    write_root_file(
        Path("/etc/apt/sources.list.d/claude-code.list"),
        "deb [signed-by=/etc/apt/keyrings/claude-code.asc] "
        "https://downloads.claude.ai/claude-code/apt/stable stable main\n",
    )
    run("apt-get", "update", "-q", sudo=True)
    run("apt-get", "install", "-y", "-q", "claude-code", sudo=True)


def linux_chrome(tmp):
    step("google chrome")
    if query("dpkg", "--print-architecture") != "amd64" or have("google-chrome"):
        say("ok", "google-chrome" if have("google-chrome") else "skipped (not amd64)")
        return
    key = tmp / "google.asc"
    download("https://dl.google.com/linux/linux_signing_key.pub", key)
    if not DRY and f":{CHROME_KEY_FPR}:" not in query("gpg", "--show-keys", "--with-colons", key):
        sys.exit("google key fingerprint mismatch")
    dearmored = tmp / "google-chrome.gpg"
    run("gpg", "--dearmor", "-o", dearmored, key)
    run("install", "-m", "0644", dearmored, "/usr/share/keyrings/google-chrome.gpg", sudo=True)
    write_root_file(
        Path("/etc/apt/sources.list.d/google-chrome.sources"),
        "Types: deb\n"
        "URIs: https://dl.google.com/linux/chrome-stable/deb/\n"
        "Suites: stable\n"
        "Components: main\n"
        "Architectures: amd64\n"
        "Signed-By: /usr/share/keyrings/google-chrome.gpg\n",
    )
    run("apt-get", "update", "-q", sudo=True)
    run("apt-get", "install", "-y", "-q", "google-chrome-stable", sudo=True)


def linux_login_shell():
    step("login shell")
    user = query("id", "-un")
    shell = query("getent", "passwd", user).split(":")[-1]
    if shell == "/usr/bin/zsh":
        say("ok", shell)
    else:
        run("chsh", "-s", "/usr/bin/zsh", user, sudo=True)


def in_plasma():
    return have("kwriteconfig6") and bool(os.environ.get("KDE_SESSION_VERSION"))


def kde_keys():
    term = "com.mitchellh.ghostty.desktop" if have("ghostty") else "org.kde.konsole.desktop"
    return KDE_KEYS + [("kglobalshortcutsrc", f"services/{term}", "_launch", "Meta+Return")]


def kde_apply():
    step("kde")
    for file, groups, key, value in kde_keys():
        args = ["kwriteconfig6", "--file", file]
        for g in groups.split("/"):
            args += ["--group", g]
        args += ["--key", key]
        args += ["--delete"] if value is None else [value]
        run(*args)
    if have("kbuildsycoca6"):
        run("kbuildsycoca6", check=False, quiet=True)
    if have("qdbus6"):
        run("qdbus6", "org.kde.KWin", "/KWin", "reconfigure", check=False, quiet=True)
    run("systemctl", "--user", "restart", "plasma-kglobalaccel.service", check=False)
    say("applied", "keyboard and shortcuts fully apply on next login")


def linux_sync():
    run("sudo", "-v")
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        linux_packages()
        linux_font(tmp)
        lite_xl(tmp)
        linux_ghostty(tmp)
        linux_keyd()
        linux_claude_code(tmp)
        linux_chrome(tmp)
        linux_login_shell()
    if read_state("kde") != digest(kde_keys()):
        if in_plasma():
            kde_apply()
            write_state("kde", digest(kde_keys()))
        else:
            say("later", "not a Plasma session; run setup.py again after login to apply KDE settings")


# ---------------------------------------------------------------- macos


def brew_path():
    for candidate in ("/opt/homebrew/bin/brew", "/usr/local/bin/brew"):
        if os.access(candidate, os.X_OK):
            return candidate
    return None


def macos_homebrew():
    step("homebrew")
    if brew_path() is None:
        if DRY:
            say("would run", "the Homebrew installer (https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh), then brew update/bundle/upgrade")
            return
        run("sudo", "-v")
        with urllib.request.urlopen("https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh") as r:
            installer = r.read().decode()
        run("/bin/bash", "-c", installer, env=dict(os.environ, NONINTERACTIVE="1"))
    brew = brew_path()
    prefix = str(Path(brew).parent.parent)
    os.environ["PATH"] = f"{prefix}/bin:{prefix}/sbin:{os.environ['PATH']}"
    os.environ["HOMEBREW_NO_ANALYTICS"] = "1"
    run(brew, "update", "-q")
    run(brew, "bundle", f"--file={REPO / 'os/Brewfile'}")
    run(brew, "upgrade", "-q")
    run(brew, "autoremove", "-q")
    run(brew, "cleanup", "-q", "--prune=all", check=False, quiet=True)


def launch_agent(label, source):
    uid = os.getuid()
    dest = HOME / "Library/LaunchAgents" / f"{label}.plist"
    fresh = not (dest.exists() and filecmp.cmp(source, dest, shallow=False))
    if fresh:
        if not DRY:
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, dest)
        say("wrote", dest)
        run("launchctl", "bootout", f"gui/{uid}/{label}", check=False)
    else:
        say("ok", dest)
    if fresh or query("launchctl", "print", f"gui/{uid}/{label}") == "":
        if run("launchctl", "bootstrap", f"gui/{uid}", dest, check=False).returncode != 0:
            say("later", f"{label} not loaded now (no GUI session?); it loads at next login")


def macos_sync():
    macos_homebrew()
    with tempfile.TemporaryDirectory() as tmpdir:
        lite_xl(Path(tmpdir))
    step("keyboard: swap caps lock and left ctrl")
    launch_agent("com.dotfiles.capslock", REPO / "os/macos/capslock.plist")

    step("login shell")
    shell = query("dscl", ".", "-read", str(HOME), "UserShell").split()[-1:]
    if shell == ["/bin/zsh"]:
        say("ok", "/bin/zsh")
    else:
        run("chsh", "-s", "/bin/zsh")

    step("zsh completion dirs")
    insecure = query("zsh", "-c", "autoload -Uz compaudit; compaudit").split()
    for d in insecure:
        run("chmod", "g-w,o-w", d, check=False)

    if read_state("defaults") != digest(MACOS_DEFAULTS):
        step("defaults")
        for row in MACOS_DEFAULTS:
            run("defaults", *row)
        run("killall", "Dock", "Finder", check=False)
        write_state("defaults", digest(MACOS_DEFAULTS))


# ---------------------------------------------------------------- commands


def sync(profile):
    step("repo")
    if run("git", "-C", REPO, "pull", "-q", "--ff-only", check=False).returncode != 0:
        say("warn", "pull failed (offline or diverged); continuing with the local tree")
    run("git", "-C", REPO, "submodule", "update", "--init", "-q")

    step(f"links ({profile})")
    link_all(link_table(profile))
    os.environ["PATH"] = f"{BIN}:{os.environ['PATH']}"

    if OS == "Linux":
        linux_sync()
    else:
        macos_sync()

    step("done")
    print(
        "  0. open a new terminal (or: exec zsh) for shell changes\n"
        "  1. log out / in  (login shell, session env, keyboard remap)\n"
        "  2. claude        # log in, then:\n"
        "     jq -r '.enabledPlugins | keys[]' ~/.claude/settings.json | xargs -n1 claude plugin install\n"
        f"  3. python3 {REPO / 'setup.py'} check"
    )


def main():
    global DRY
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", nargs="?", default="sync", choices=("sync", "link", "check"))
    parser.add_argument("--profile", choices=PROFILES, help="work or personal; remembered after the first run")
    parser.add_argument("--dry-run", action="store_true", help="print commands instead of running them")
    args = parser.parse_args()
    DRY = args.dry_run
    if OS not in ("Linux", "Darwin"):
        sys.exit(f"unsupported OS: {OS}")

    profile = resolve_profile(args.profile)
    if args.command == "check":
        sys.exit(0 if check_all(link_table(profile)) else 1)
    if args.command == "link":
        link_all(link_table(profile))
        return
    sync(profile)


if __name__ == "__main__":
    main()
