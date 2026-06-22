#!/usr/bin/env bash
#
# install.sh - Detect the distro (Fedora/dnf or Ubuntu/apt) and run setup/ in order.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"

# --- Configuration -----------------------------------------------------------

# Seed .env from .env.example on first run, then load it.
# Usage: prepare_env
prepare_env() {
    if [ ! -f "$DOTFILES/.env" ] && [ -f "$DOTFILES/.env.example" ]; then
        cp "$DOTFILES/.env.example" "$DOTFILES/.env"
        warning "Created $DOTFILES/.env from template — edit it with your values."
    fi
    load_env
}

# --- Setup scripts -----------------------------------------------------------

# Run every setup/*.sh in order.
# Usage: run_setup
run_setup() {
    local script name found=0
    for script in "$DOTFILES"/setup/*.sh; do
        [ -f "$script" ] || continue
        found=1
        name="$(basename "$script")"
        log "==> $name"
        bash "$script"
    done
    [ "$found" -eq 1 ] || info "setup/ is empty; nothing to run yet."
}

# --- Main --------------------------------------------------------------------

# Entry point: detect the OS, prepare env, and run the setup scripts.
# Usage: main
main() {
    log "=== Dotfiles installation ==="
    info "Repo: $DOTFILES"

    detect_os
    os_summary
    prepare_env

    run_setup

    success "Done."
}

main
