#!/usr/bin/env bash
#
# setup/05-java.sh - Install a Java toolchain via SDKMAN (Java SDK, Maven, Gradle).
# SDKMAN appends init lines to ~/.bashrc / ~/.zshrc, so a new shell is needed for sdk/java/mvn/gradle on PATH.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"
source "$DOTFILES/lib/pkgmanager.sh"

detect_os

SDKMAN_DIR="$HOME/.sdkman"

# Install a SDKMAN candidate unless it is already the current selection.
# Usage: install_or_skip <candidate> | Example: install_or_skip maven
install_or_skip() {
    local candidate="$1"
    # SDKMAN's internal scripts reference unset positional params (e.g. $2 for
    # an omitted version).
    set +u
    if sdk current "$candidate" >/dev/null 2>&1; then
        info "$candidate already installed via SDKMAN; skipping."
    else
        log "Installing $candidate via SDKMAN..."
        sdk install "$candidate"
    fi
    set -u
}

# --- SDKMAN Prerequisites ----------------------------------------------------
log "Installing SDKMAN prerequisites..."
pkg_install curl zip unzip

# --- SDKMAN ------------------------------------------------------------------
if [ -d "$SDKMAN_DIR" ]; then
    info "SDKMAN already installed at $SDKMAN_DIR; skipping install."
else
    log "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
fi

# Load SDKMAN into the current shell so we can drive `sdk`.
set +u

source "$SDKMAN_DIR/bin/sdkman-init.sh"
set -u

# --- SDKs --------------------------------------------------------------------
install_or_skip java
install_or_skip maven
install_or_skip gradle

success "Java toolchain (SDKMAN) setup complete."