#!/usr/bin/env bash
#
# setup/00-system-update.sh - Refresh package metadata and upgrade the system.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"
source "$DOTFILES/lib/pkgmanager.sh"

detect_os

log "Updating package metadata..."
pkg_update

log "Upgrading installed packages..."
pkg_upgrade

success "System is up to date."
