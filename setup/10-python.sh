#!/usr/bin/env bash
#
# setup/10-python.sh - Install a Python toolchain via uv (latest stable CPython as default).
# uv is installed into ~/.local/bin and does not edit ~/.bashrc. shell/shared/env.sh already
# prepends that directory, so a new shell is needed before uv/python resolve.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"
source "$DOTFILES/lib/pkgmanager.sh"

detect_os

UV_BIN="$HOME/.local/bin/uv"

# --- Prerequisites -----------------------------------------------------------
log "Installing uv prerequisites..."
pkg_install curl

# --- uv ----------------------------------------------------------------------
if have uv || [ -x "$UV_BIN" ]; then
    info "uv already installed; skipping install."
else
    log "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi

export PATH="$HOME/.local/bin:$PATH"

# --- Python ------------------------------------------------------------------
log "Installing the latest stable Python (uv skips it if already present)..."
uv python install --default

warning "Open a new shell (or ensure ~/.local/bin is on PATH) to use uv/python."

success "Python (uv) setup complete."
