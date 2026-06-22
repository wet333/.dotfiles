#!/usr/bin/env bash
#
# setup/06-node.sh - Install a Node.js toolchain via fnm (latest LTS as default, pnpm via corepack).
# fnm appends init lines to ~/.bashrc / ~/.zshrc, so a new shell is needed for fnm/node/npm/pnpm on PATH.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"
source "$DOTFILES/lib/pkgmanager.sh"

detect_os

FNM_DIR="$HOME/.local/share/fnm"

# --- Prerequisites -----------------------------------------------------------
log "Installing fnm prerequisites..."
pkg_install curl unzip

# --- fnm ---------------------------------------------------------------------
if have fnm || [ -d "$FNM_DIR" ]; then
    info "fnm already installed; skipping install."
else
    log "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash
fi

# Load fnm into the current shell so we can drive it.
export PATH="$FNM_DIR:$PATH"
eval "$(fnm env)"

# --- Node.js LTS -------------------------------------------------------------
log "Installing the latest Node.js LTS (fnm skips it if already present)..."
fnm install --lts
fnm default lts-latest

# --- pnpm (via corepack) -----------------------------------------------------
if have corepack; then
    log "Enabling pnpm via corepack..."
    corepack enable pnpm
else
    warning "corepack not found; skipping pnpm enablement."
fi

warning "Open a new shell (or 'eval \"\$(fnm env)\"') to use fnm/node/npm/pnpm."

success "Node.js (fnm) setup complete."
