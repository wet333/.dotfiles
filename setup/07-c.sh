#!/usr/bin/env bash
#
# setup/07-c.sh - Install the C/C++ toolchain (gcc/g++, make, cmake, gdb, valgrind, headers).
# Package names differ per distro, so the lists are hardcoded below, per distro.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"
source "$DOTFILES/lib/pkgmanager.sh"

detect_os

log "Installing C/C++ toolchain packages..."

# C/C++ toolchain shared across distros.
pkg_install gcc make cmake gdb valgrind

# Distro-specific toolchain packages.
case "$PKG_MGR" in
    dnf) pkg_install gcc-c++ glibc-devel kernel-headers ;;
    apt) pkg_install g++ build-essential linux-headers-generic ;;
esac

success "C/C++ toolchain setup complete."
