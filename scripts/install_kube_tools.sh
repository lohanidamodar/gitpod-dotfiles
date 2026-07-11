#!/usr/bin/env bash
# Kubernetes toolkit for running/debugging clusters (Appwrite Cloud, DO DOKS):
#   kubectl   the cluster CLI
#   helm      chart/package manager (Appwrite ships Helm charts)
#   k9s       terminal UI for clusters
#   kubectx   fast context switching
#   kubens    fast namespace switching
#   stern     tail logs across many pods at once
# mac uses Homebrew; Linux uses native packages where solid, else the official
# binary/GitHub-release (the pattern this repo already uses for doctl/eza).
#
# Tip (DigitalOcean): after doctl auth, pull a DOKS kubeconfig with
#   doctl kubernetes cluster kubeconfig save <cluster>
set -uo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

# ---- macOS: one brew line does it all --------------------------------------
if is_mac; then
    info "installing kube tools via brew"
    # kubectx formula provides both kubectx and kubens.
    pkg_install kubectl helm k9s kubectx stern || warn "some brew kube tools failed"
    info "kube tools done."
    exit 0
fi

# ---- Linux -----------------------------------------------------------------
need_cmd curl || pkg_install curl
need_cmd tar  || pkg_install tar

case "$(uname -m)" in
    x86_64)        GOARCH=amd64; ALT=x86_64 ;;
    aarch64|arm64) GOARCH=arm64; ALT=arm64  ;;
    *) err "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

latest_tag() {  # latest_tag <owner/repo>  ->  vX.Y.Z
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | grep -Po '"tag_name": *"\K[^"]+'
}
install_bin() { $SUDO install -m 0755 "$1" "/usr/local/bin/$2"; }   # install_bin <src> <name>

# ---- kubectl (official binary; most reliable across distros) ----------------
if need_cmd kubectl; then
    info "kubectl already installed: $(kubectl version --client -o yaml 2>/dev/null | grep -m1 gitVersion || echo present)"
else
    ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
    if [ -n "$ver" ] && curl -fsSL "https://dl.k8s.io/release/${ver}/bin/linux/${GOARCH}/kubectl" -o "$tmp/kubectl"; then
        install_bin "$tmp/kubectl" kubectl && info "kubectl ${ver} installed"
    else
        warn "kubectl download failed"
    fi
fi

# ---- helm (official script, no sudo, into ~/.local/bin) ---------------------
if need_cmd helm; then
    info "helm already installed: $(helm version --short 2>/dev/null)"
else
    mkdir -p "$HOME/.local/bin"
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
        | USE_SUDO=false HELM_INSTALL_DIR="$HOME/.local/bin" bash \
        && info "helm installed to ~/.local/bin" || warn "helm install failed"
fi

# ---- k9s (native pkg, else GitHub release — static asset name) --------------
if need_cmd k9s; then
    info "k9s already installed"
else
    pkg_install k9s 2>/dev/null || true
    if ! need_cmd k9s; then
        if curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${GOARCH}.tar.gz" -o "$tmp/k9s.tgz"; then
            tar -xzf "$tmp/k9s.tgz" -C "$tmp" k9s && install_bin "$tmp/k9s" k9s && info "k9s installed"
        else
            warn "k9s download failed"
        fi
    fi
fi

# ---- kubectx + kubens (native pkg provides both, else GitHub release) --------
if need_cmd kubectx && need_cmd kubens; then
    info "kubectx/kubens already installed"
else
    pkg_install kubectx 2>/dev/null || true
    if ! need_cmd kubectx || ! need_cmd kubens; then
        if t="$(latest_tag ahmetb/kubectx)" && [ -n "$t" ]; then
            for tool in kubectx kubens; do
                need_cmd "$tool" && continue
                if curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/${t}/${tool}_${t}_linux_${ALT}.tar.gz" -o "$tmp/${tool}.tgz"; then
                    tar -xzf "$tmp/${tool}.tgz" -C "$tmp" "$tool" && install_bin "$tmp/$tool" "$tool" && info "$tool installed"
                else
                    warn "$tool download failed"
                fi
            done
        else
            warn "couldn't resolve latest kubectx release"
        fi
    fi
fi

# ---- stern (native pkg, else GitHub release — version in asset name) --------
if need_cmd stern; then
    info "stern already installed"
else
    pkg_install stern 2>/dev/null || true
    if ! need_cmd stern; then
        if t="$(latest_tag stern/stern)" && [ -n "$t" ]; then
            v="${t#v}"
            if curl -fsSL "https://github.com/stern/stern/releases/download/${t}/stern_${v}_linux_${GOARCH}.tar.gz" -o "$tmp/stern.tgz"; then
                tar -xzf "$tmp/stern.tgz" -C "$tmp" stern && install_bin "$tmp/stern" stern && info "stern installed"
            else
                warn "stern download failed"
            fi
        else
            warn "couldn't resolve latest stern release"
        fi
    fi
fi

info "kube tools done. (kubectl / helm / k9s / kubectx / kubens / stern)"
