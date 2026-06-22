#!/usr/bin/env bash
#
# shell/shared/functions/fs.sh - Filesystem navigation helpers. Sourced by the shell init scripts.

# Create a directory (and parents) then cd into it.
# Usage: mkcd <dir> | Example: mkcd ~/dev/newproject
mkcd() {
    mkdir -p -- "$1" && cd -- "$1"
}

# Extract a compressed archive based on its extension.
# Usage: extract <archive> | Example: extract release.tar.gz
extract() {
    [ -f "$1" ] || { echo "extract: '$1' is not a file" >&2; return 1; }
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz)         tar xJf "$1" ;;
        *.tar)            tar xf  "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.gz)             gunzip  "$1" ;;
        *.zip)            unzip   "$1" ;;
        *.7z)             7z x    "$1" ;;
        *.rar)            unrar x "$1" ;;
        *)                echo "extract: don't know how to extract '$1'" >&2; return 1 ;;
    esac
}
