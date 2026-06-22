#!/usr/bin/env bash
#
# setup/08-shell.sh - Wire the dotfiles bash shell config into ~/.bashrc.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"

log "Wiring bash shell config into ~/.bashrc..."

# Guarded block that exports DOTFILES and sources our bash entry point.
ensure_block "$HOME/.bashrc" "dotfiles-shell" "export DOTFILES=\"$DOTFILES\"
[ -r \"\$DOTFILES/shell/bash/init.sh\" ] && . \"\$DOTFILES/shell/bash/init.sh\""

success "Shell config wired into ~/.bashrc."
info "Open a new shell or run 'source ~/.bashrc' to load it."
