# dotfiles

Cross-distro dev-environment setup for **Arch, Debian/Ubuntu, Fedora** (and
openSUSE/Alpine where practical), including under **WSL**. Installs a fish +
tmux shell environment and a pick-and-choose set of dev tools.

Every install is a toggle. A plain run installs a lean base; AI coding CLIs and
extra languages are **opt-in**.

## Prerequisites

Just `git` and `curl` (the one-liner below fetches over curl and clones over
git). Install them first on a fresh box — drop `sudo` if you're already root:

```bash
# Arch
sudo pacman -Sy --needed --noconfirm git curl
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y git curl
# Fedora
sudo dnf install -y git curl
```

> **Fresh Arch/WSL running as root?** Create a non-root sudo user first (this
> also installs `sudo`), then run everything as that user:
> ```bash
> bash scripts/create_sudo_user.sh <username>   # run as root
> ```

## Quick start

Bootstrap directly (clones to `~/.dotfiles`, then runs `setup.sh`):

```bash
curl -fsSL https://raw.githubusercontent.com/lohanidamodar/gitpod-dotfiles/main/install.sh | bash
```

Or clone and run manually:

```bash
git clone https://github.com/lohanidamodar/gitpod-dotfiles.git ~/.dotfiles
bash ~/.dotfiles/setup.sh
```

Re-running is safe: the bootstrap `git pull`s an existing clone, and every
installer skips work that's already done.

## What the default run installs

| Tool | Env var | What it is |
|------|---------|-----------|
| OpenSSH client | `INSTALL_SSH` | `ssh`, `scp`, `ssh-keygen`, agent |
| Docker | `INSTALL_DOCKER` | engine + compose |
| fish | `INSTALL_FISH` | shell + this repo's config |
| (set fish default) | `SET_FISH_DEFAULT` | `chsh` to fish |
| tmux | `INSTALL_TMUX` | tmux + Catppuccin config + TPM plugins |
| Nerd Fonts | `INSTALL_NERD_FONT` | JetBrainsMono + Symbols (for icons) |
| Node.js | `INSTALL_NODE` | node + npm |
| Bun | `INSTALL_BUN` | bun |
| GitHub CLI | `INSTALL_GH` | `gh` |
| DigitalOcean CLI | `INSTALL_DOCTL` | `doctl` |

Skip any of them by setting its var to `0`:

```bash
INSTALL_DOCKER=0 bash ~/.dotfiles/setup.sh
```

## Opt-in installs (default off)

Enable by setting the var to `1`. These are **not** installed by a plain run.

| Tool | Env var | Notes |
|------|---------|-------|
| Claude Code CLI | `INSTALL_CLAUDE` | AI coding CLI |
| OpenAI Codex CLI | `INSTALL_CODEX` | AI coding CLI |
| Google Antigravity CLI | `INSTALL_ANTIGRAVITY` | AI coding CLI |
| Flutter | `INSTALL_FLUTTER` | heavy; bundles Dart |
| Dart | `INSTALL_DART` | standalone Dart SDK |
| PHP | `INSTALL_PHP` | latest stable + common extensions |
| Composer | `INSTALL_COMPOSER` | implies PHP |
| Ruby | `INSTALL_RUBY` | + bundler |
| Swift | `INSTALL_SWIFT` | swiftly (apt/dnf) / AUR (Arch) |
| eza | `INSTALL_EZA` | modern `ls` (fish aliases prefer it) |
| Ollama | `INSTALL_OLLAMA` | `ollama` CLI |

### Copy-paste examples

```bash
# Add the Claude CLI to an otherwise-default run
INSTALL_CLAUDE=1 bash ~/.dotfiles/setup.sh

# All three AI coding CLIs
INSTALL_CLAUDE=1 INSTALL_CODEX=1 INSTALL_ANTIGRAVITY=1 bash ~/.dotfiles/setup.sh

# PHP + Composer (installing Composer pulls PHP in automatically)
INSTALL_COMPOSER=1 bash ~/.dotfiles/setup.sh

# A PHP/Ruby web-dev box
INSTALL_PHP=1 INSTALL_COMPOSER=1 INSTALL_RUBY=1 bash ~/.dotfiles/setup.sh

# Flutter (+ Dart) mobile setup
INSTALL_FLUTTER=1 bash ~/.dotfiles/setup.sh

# Pass toggles through the curl bootstrap
curl -fsSL https://raw.githubusercontent.com/lohanidamodar/gitpod-dotfiles/main/install.sh | INSTALL_CLAUDE=1 bash
```

### Run a single installer

Every tool has a standalone, cross-distro script you can run on its own:

```bash
bash ~/.dotfiles/scripts/install_php.sh        # latest stable PHP
bash ~/.dotfiles/scripts/install_claude_cli.sh # Claude CLI
bash ~/.dotfiles/scripts/install_tmux.sh        # tmux + config + plugins
bash ~/.dotfiles/scripts/install_eza.sh         # eza
# ...see scripts/ for the full list
```

## tmux

Config is installed to `~/.config/tmux/tmux.conf` (Catppuccin Mocha theme).
The prefix is **`Ctrl+Space`**. Highlights:

- Splits: `prefix + |` (vertical), `prefix + -` (horizontal) — open in the current dir
- Panes: `prefix + h/j/k/l` to move, `prefix + H/J/K/L` to resize, `prefix + m` to zoom
- Windows: `Shift+←/→` (no prefix), new window `prefix + c`
- Reload: `prefix + r`
- Copy mode (vi): `prefix + v`, `y` to yank (pipes to the Windows clipboard on WSL)

Alt-based keys are intentionally avoided so they stay free for the GlazeWM.

## WSL notes

- **Fonts** render on the *Windows* side. The installer drops `.ttf` files in
  `~/.local/share/fonts/` and installs them in Linux, but for Windows Terminal
  you must also install the same "JetBrainsMono Nerd Font" on Windows and pick
  it in your terminal settings.
- **SSH agent sharing** (pick one direction), after `setup.sh`:
  ```bash
  bash ~/.dotfiles/scripts/setup_wsl_ssh_agent.sh   # keys in Windows, use from WSL
  bash ~/.dotfiles/scripts/wsl_ssh_agent_serve.sh   # keys in WSL, use from Windows
  ```

## After installing

Open a new shell (or `exec fish`) to pick up PATH and shell changes.
