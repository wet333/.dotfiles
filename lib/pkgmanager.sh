#!/usr/bin/env bash
#
# lib/pkgmanager.sh - Package-manager abstraction (dnf / apt). Sourced, not executed.
# Depends on lib/common.sh (logging) and PKG_MGR from detect_os() (call detect_os first).

# Refresh the package manager's metadata/indexes.
# Usage: pkg_update
pkg_update() {
    case "$PKG_MGR" in
        dnf) sudo dnf -y makecache ;;
        apt) sudo apt-get update -y ;;
        *)   error "pkg_update: unsupported PKG_MGR: '$PKG_MGR'"; return 1 ;;
    esac
}

# Upgrade all installed packages (non-interactive).
# Usage: pkg_upgrade
pkg_upgrade() {
    case "$PKG_MGR" in
        dnf) sudo dnf -y upgrade ;;
        apt) sudo apt-get -y upgrade ;;
        *)   error "pkg_upgrade: unsupported PKG_MGR: '$PKG_MGR'"; return 1 ;;
    esac
}

# Install packages non-interactively.
# Usage: pkg_install <pkgs...> | Example: pkg_install git curl
pkg_install() {
    [ "$#" -gt 0 ] || { warning "pkg_install: no packages given"; return 0; }
    case "$PKG_MGR" in
        dnf) sudo dnf install -y "$@" ;;
        apt) sudo apt-get install -y "$@" ;;
        *)   error "pkg_install: unsupported PKG_MGR: '$PKG_MGR'"; return 1 ;;
    esac
}

# Test whether a package is installed (for idempotency).
# Usage: pkg_installed <pkg> | Example: pkg_installed docker-ce
pkg_installed() {
    local pkg="$1"
    case "$PKG_MGR" in
        dnf) rpm -q "$pkg" >/dev/null 2>&1 ;;
        apt) dpkg -s "$pkg" >/dev/null 2>&1 ;;
        *)   return 1 ;;
    esac
}
