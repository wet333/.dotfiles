#!/usr/bin/env bash
#
# setup/01-core-packages.sh - Install core CLI packages (lists hardcoded below, per distro).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"
source "$DOTFILES/lib/pkgmanager.sh"

detect_os

log "Installing core CLI packages..."

# Core CLI tools, daily drivers (same name on both distros).
pkg_install wget curl htop tree tmux unzip ncdu ca-certificates

# Distro-specific names for the same tools.
case "$PKG_MGR" in
    dnf) pkg_install vim-enhanced gnupg2 ;;
    apt) pkg_install vim gnupg ;;
esac

success "Core packages installed."
