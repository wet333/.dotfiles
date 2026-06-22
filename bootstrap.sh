#!/usr/bin/env bash
#
# bootstrap.sh - Install git, clone the repo and run install.sh on a clean system (no dependencies).
# Usage: curl -fsSL https://raw.githubusercontent.com/wet333/dotfiles/master/bootstrap.sh | bash
# Optional env: DOTFILES_DIR (clone dest, default $HOME/.dotfiles), DOTFILES_REPO (URL), DOTFILES_REF (branch/tag, default master).

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/wet333/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
DOTFILES_REF="${DOTFILES_REF:-master}"

say()  { printf '\e[1;34m[bootstrap]\e[0m %s\n' "$*"; }
die()  { printf '\e[1;31m[bootstrap]\e[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Echo the package manager (dnf|apt); minimal, install.sh does full detection.
# Usage: detect_pkg_mgr
detect_pkg_mgr() {
    if have dnf; then echo dnf
    elif have apt-get; then echo apt
    else die "Neither dnf nor apt-get found. Unsupported distro."
    fi
}

# Install git if it is missing.
# Usage: ensure_git
ensure_git() {
    have git && return 0
    say "git is not installed; installing it..."
    case "$(detect_pkg_mgr)" in
        dnf) sudo dnf install -y git ;;
        apt) sudo apt-get update -y && sudo apt-get install -y git ;;
    esac
    have git || die "Could not install git."
}

# Clone the repo, or fast-forward it if already present.
# Usage: clone_or_update
clone_or_update() {
    if [ -d "$DOTFILES_DIR/.git" ]; then
        say "Repo already present at $DOTFILES_DIR; updating..."
        git -C "$DOTFILES_DIR" pull --ff-only || say "Could not update (continuing with local copy)."
    else
        say "Cloning $DOTFILES_REPO -> $DOTFILES_DIR"
        git clone --branch "$DOTFILES_REF" "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
}

# Entry point: ensure git, clone/update the repo, then exec install.sh.
# Usage: main "$@"
main() {
    say "Starting dotfiles bootstrap"
    ensure_git
    clone_or_update
    [ -f "$DOTFILES_DIR/install.sh" ] || die "install.sh not found in $DOTFILES_DIR"
    say "Running install.sh"
    exec bash "$DOTFILES_DIR/install.sh" "$@"
}

main "$@"
