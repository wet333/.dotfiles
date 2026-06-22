#!/usr/bin/env bash
#
# lib/os.sh - Distro detection and system-service helpers. Sourced, not executed; depends on lib/common.sh.

# Detect the distro and export OS_ID, OS_NAME, PKG_MGR (dnf|apt) and OS_FAMILY (rhel|debian).
# Usage: detect_os
detect_os() {
    # /etc/os-release ID is NOT used to pick the PM: derivatives like Nobara ship ID=nobara.
    OS_ID="unknown"; OS_NAME="unknown"
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_NAME="${NAME:-unknown}"
    fi

    # The present package manager is the source of truth.
    if have dnf; then
        PKG_MGR="dnf"
        OS_FAMILY="rhel"
    elif have apt-get; then
        PKG_MGR="apt"
        OS_FAMILY="debian"
    else
        error "No supported package manager found (dnf or apt-get)."
        return 1
    fi

    export PKG_MGR OS_ID OS_FAMILY OS_NAME
}

# Print a one-line detection summary (run detect_os first).
# Usage: os_summary
os_summary() {
    info "Detected: $OS_NAME ($PKG_MGR / $OS_FAMILY)"
}

# Enable and start a systemd service (idempotent; skipped if systemctl is absent).
# Usage: enable_service <name> | Example: enable_service docker
enable_service() {
    local svc="$1"
    have systemctl || { warning "systemctl not available; skipping enable of $svc"; return 0; }
    sudo systemctl enable --now "$svc"
}
