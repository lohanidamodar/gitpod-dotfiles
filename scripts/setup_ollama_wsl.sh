#!/usr/bin/env bash
set -euo pipefail

if [[ ! -e /proc/sys/fs/binfmt_misc/WSLInterop && -z "${WSL_DISTRO_NAME:-}" ]]; then
    echo "Not running under WSL." >&2
    exit 1
fi

dotfiles_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
src="$dotfiles_dir/fish/conf.d/ollama.fish"
dest="$HOME/.config/fish/conf.d/ollama.fish"

if [[ ! -f "$src" ]]; then
    echo "Missing $src" >&2
    exit 1
fi

mkdir -p "$(dirname "$dest")"
cp "$src" "$dest"
echo "[ok] installed $dest"

gw=$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}' || true)
if [[ -z "${gw:-}" ]]; then
    echo "Could not determine WSL gateway IP." >&2
    exit 1
fi
echo "[info] WSL gateway (Windows host): $gw"

probe() { curl --max-time 2 -fsS "http://$1:11434/api/tags" >/dev/null 2>&1; }

if probe "$gw"; then
    echo "[ok] reached Ollama at http://$gw:11434"
elif probe localhost; then
    echo "[ok] reached Ollama at http://localhost:11434 (mirrored networking)"
    echo "     consider exporting OLLAMA_HOST=http://localhost:11434 to skip the gateway lookup"
else
    cat <<'EOF' >&2
[fail] could not reach Ollama from WSL.
  1. is Ollama running on Windows? (system tray)
  2. did you run setup_ollama_windows.ps1 in an admin PowerShell?
  3. is the firewall rule "Ollama (WSL)" present?
       powershell: Get-NetFirewallRule -DisplayName 'Ollama (WSL)'
  4. did Ollama restart AFTER the env vars were set?
EOF
    exit 1
fi

echo
echo "Open a new fish shell, then test:"
echo "  echo \$OLLAMA_HOST"
echo "  curl \$OLLAMA_HOST/api/tags"
