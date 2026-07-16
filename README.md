# dotfiles

Cross-platform dev-environment setup for **macOS** and **Arch, Debian/Ubuntu,
Fedora** (and openSUSE/Alpine where practical), including under **WSL**.
Installs a zsh + tmux shell environment and a pick-and-choose set of dev tools.
macOS installs everything through **Homebrew** (auto-installed if missing);
Linux uses the native package manager.

Every install is a toggle. A plain run installs a lean base; AI coding CLIs and
extra languages are **opt-in**.

## Prerequisites

Just `git` and `curl` (the one-liner below fetches over curl and clones over
git). macOS ships both. On a fresh Linux box install them first — drop `sudo`
if you're already root:

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
# Default install (the base set below)
curl -fsSL https://raw.githubusercontent.com/lohanidamodar/gitpod-dotfiles/main/install.sh | bash

# Interactive — pick what to install from a menu
curl -fsSL https://raw.githubusercontent.com/lohanidamodar/gitpod-dotfiles/main/install.sh | INTERACTIVE=1 bash
```

Or clone and run manually:

```bash
git clone https://github.com/lohanidamodar/gitpod-dotfiles.git ~/.dotfiles
bash ~/.dotfiles/setup.sh          # default install
bash ~/.dotfiles/setup.sh -i       # interactive menu (or --interactive)
```

Re-running is safe: the bootstrap `git pull`s an existing clone, and every
installer skips work that's already done.

### Interactive mode

You get an arrow-key checklist (pre-checked to the defaults below) grouped by
category: **↑/↓** (or `j`/`k`) to move, **Space** to toggle, `a`/`n` for
all/none, `d` to reset to defaults, **Enter** to install, `q` to quit. It
scrolls when the list is taller than your window. It's dependency-free (raw-key
bash, no `gum`/`fzf`/`whiptail`) and reads the terminal directly, so it also
works through the curl bootstrap (and falls back to a numbered menu if there's
no arrow-key-capable terminal):

```bash
curl -fsSL https://raw.githubusercontent.com/lohanidamodar/gitpod-dotfiles/main/install.sh | INTERACTIVE=1 bash
```

The default (non-interactive) run is unchanged.

## What the default run installs

| Tool | Env var | What it is |
|------|---------|-----------|
| OpenSSH client | `INSTALL_SSH` | `ssh`, `scp`, `ssh-keygen`, agent |
| Docker | `INSTALL_DOCKER` | engine + compose (native repos on Linux; [Dory](https://github.com/Augani/dory) — open-source, macOS-native containers — on macOS) |
| zsh | `INSTALL_ZSH` | shell + plugins (autosuggestions, syntax highlight) + starship + this repo's `~/.zshrc` |
| (set zsh default) | `SET_ZSH_DEFAULT` | `chsh` to zsh |
| git config | `INSTALL_GITCONFIG` | `~/.gitconfig` (delta, aliases, sane defaults); identity kept in `~/.gitconfig.local` |
| herdr | `INSTALL_HERDR` | AI-agent-aware terminal multiplexer + config (the default; tmux alternative) |
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
| fish | `INSTALL_FISH` | shell + this repo's config (zsh is the default) |
| tmux | `INSTALL_TMUX` | tmux + Catppuccin config + TPM plugins (herdr is the default multiplexer) |
| Claude Code CLI | `INSTALL_CLAUDE` | AI coding CLI |
| OpenAI Codex CLI | `INSTALL_CODEX` | AI coding CLI |
| Google Antigravity CLI | `INSTALL_ANTIGRAVITY` | AI coding CLI |
| Flutter | `INSTALL_FLUTTER` | heavy; bundles Dart |
| Flutter build deps | `INSTALL_FLUTTER_DEPS` | JDK 17 + Android Studio + Android SDK + Xcode CLT (mac) + CocoaPods (mac) + fastlane |
| Dart | `INSTALL_DART` | standalone Dart SDK |
| PHP | `INSTALL_PHP` | latest stable + common extensions |
| Swoole | `INSTALL_SWOOLE` | add Swoole to PHP (Appwrite core); best-effort per manager |
| Composer | `INSTALL_COMPOSER` | implies PHP |
| Ruby | `INSTALL_RUBY` | + bundler |
| Swift | `INSTALL_SWIFT` | swiftly (apt/dnf) / AUR (Arch) |
| Kubernetes tools | `INSTALL_KUBE` | kubectl, helm, k9s, kubectx, kubens, stern |
| Appwrite CLI | `INSTALL_APPWRITE_CLI` | deploy functions, manage projects (needs Node) |
| mise | `INSTALL_MISE` | polyglot runtime version manager (Node/Flutter/PHP/…) |
| direnv | `INSTALL_DIRENV` | per-directory env via `.envrc` |
| yq | `INSTALL_YQ` | YAML/JSON processor (compose + k8s manifests) |
| VS Code | `INSTALL_VSCODE` | Visual Studio Code + `code` CLI (brew cask / MS repo / snap / flatpak). `INSTALL_VSCODE_EXTENSIONS=1` adds Flutter, PHP, Docker, ESLint/Prettier, GitLens, YAML, k8s extensions |
| Modern CLI utils | `INSTALL_SHELL_UTILS` | eza, bat, fd, ripgrep, fzf, zoxide, git-delta, duf, btop, jq, tealdeer |
| eza | `INSTALL_EZA` | just eza (a subset of the bundle above) |
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

# Flutter app dev: SDK + full mobile toolchain (JDK, Android Studio/SDK, CocoaPods, fastlane)
INSTALL_FLUTTER=1 INSTALL_FLUTTER_DEPS=1 bash ~/.dotfiles/setup.sh

# Appwrite platform + cloud: PHP+Swoole, Appwrite CLI, Kubernetes, yq, direnv, AI CLIs
INSTALL_PHP=1 INSTALL_SWOOLE=1 INSTALL_COMPOSER=1 INSTALL_APPWRITE_CLI=1 \
  INSTALL_KUBE=1 INSTALL_YQ=1 INSTALL_DIRENV=1 INSTALL_MISE=1 \
  INSTALL_CLAUDE=1 INSTALL_CODEX=1 bash ~/.dotfiles/setup.sh

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

## herdr (default multiplexer)

[herdr](https://github.com/ogulcancelik/herdr) is a Rust, AI-agent-aware terminal
multiplexer — like tmux, but it detects the AI coding agents (Claude Code, Codex,
…) running in each pane and shows their state (working / blocked / done / idle) in
a sidebar. It's the default here; start it by running `herdr`.

Config is installed to `~/.config/herdr/config.toml` (TOML). This repo sets the
prefix to **`Ctrl+Space`** (matching the old tmux muscle memory), zsh as the
shell, and the Catppuccin theme. Detach with `Ctrl+Space q` (prefix + `q`) and
reattach by running `herdr` again. Full reference: <https://herdr.dev/docs/>.

## tmux (opt-in)

tmux is still available with `INSTALL_TMUX=1` (herdr is the default). Config is
installed to `~/.config/tmux/tmux.conf` (Catppuccin Mocha theme).
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

## Shell

zsh is the default login shell. The deployed `~/.zshrc` (from `zsh/.zshrc`)
loads Homebrew (macOS or Linuxbrew), zsh-autosuggestions, zsh-syntax-highlighting,
and the starship prompt, finding each wherever your package manager put it. It's
a portable version of a macOS `~/.zshrc`, so it works the same on macOS and Linux.
fish is still available opt-in with `INSTALL_FISH=1`.

It also carries the aliases/functions ported from the fish config (`ls`/`ll`/`la`/`lt`,
git `gco`/`gcb`/`gl`, docker `dc`/`dcl`/…, composer, `..`/`...`, `copy`, `backup`),
and initializes the modern CLI tools when present. Every alias degrades
gracefully — e.g. `ls` uses `eza` if installed, else GNU or BSD `ls` — so a
missing tool never breaks the shell.

The starship prompt config (`starship/starship.toml` → `~/.config/starship.toml`)
is a fast two-line setup: directory + git branch/status on line one, a bare
`❯` on line two. Its explicit `format` lists only the modules that render, so
starship never shells out to detect language/cloud versions it won't show.

### Modern CLI utils

`INSTALL_SHELL_UTILS=1` installs a curated bundle of modern replacements, and
`~/.zshrc` wires up their aliases/init automatically:

| Tool | Replaces | Tool | Replaces |
|------|----------|------|----------|
| eza | `ls` | zoxide | `cd` (`z`) |
| bat | `cat` | git-delta | git diff pager |
| fd | `find` | duf | `df` |
| ripgrep (`rg`) | `grep` | btop | `top` |
| fzf | fuzzy finder | jq / tealdeer | JSON / `tldr` help |

```bash
INSTALL_SHELL_UTILS=1 bash ~/.dotfiles/setup.sh   # or: bash ~/.dotfiles/scripts/install_shell_utils.sh
```

On Debian/Ubuntu the installer symlinks `bat`→`batcat` and `fd`→`fdfind` into
`~/.local/bin` so the usual names work. To use git-delta as your diff pager, add
it to `~/.gitconfig` (`[core] pager = delta`).

## Git

`INSTALL_GITCONFIG=1` (default on) deploys `git/.gitconfig` to `~/.gitconfig`:
git-delta as the diff pager (with a safe `less` fallback when delta isn't
installed), histogram diff, `zdiff3` conflict style, `rerere`, and handy aliases
(`st`, `co`, `cob`, `lg`, `amend`, `undo`, `wip`, …).

Your **identity is never stored in this public repo**. The config `[include]`s
`~/.gitconfig.local` (untracked), and setup.sh seeds that file from whatever
`user.name`/`user.email` you already had — so deploying never clobbers it. On a
fresh box with no identity yet, write it straight to the local file (so a later
re-deploy of `~/.gitconfig` can't overwrite it):

```bash
git config --file ~/.gitconfig.local user.name  "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

## After installing

Open a new shell (or `exec zsh`) to pick up PATH and shell changes.
