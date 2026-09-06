#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"

APPS_DIR="${HOME}/Applications"
OLD_DIR="${APPS_DIR}/.old"

appimage_key() {
    local b="${1##*/}"
    b="${b%.AppImage}"
    b="$(printf '%s' "$b" | sed -E 's/[-_.]?(x86_64|amd64|aarch64|arm64|i[36]86)$//I')"
    printf '%s' "$b" | sed -E 's/[-_. ]+[vV]?[0-9]+([.-][0-9A-Za-z]+)*$//' | tr '[:upper:]' '[:lower:]'
}

appimage_version() {
    local v
    v="$(printf '%s' "${1##*/}" | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1)" || true
    printf '%s' "$v"
}

mkdir -p -- "$APPS_DIR" "$OLD_DIR"

shopt -s nullglob
files=("$APPS_DIR"/*.AppImage)
shopt -u nullglob

if [ "${#files[@]}" -eq 0 ]; then
    info "appimage-prune: no AppImages in $APPS_DIR"
    exit 0
fi

declare -A group_lines=()

for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    base="${f##*/}"
    case "$base" in
        appimaged-*.AppImage) continue ;;
    esac
    ver="$(appimage_version "$base")"
    [ -n "$ver" ] || continue
    key="$(appimage_key "$f")"
    [ -n "$key" ] || continue
    line="${ver}"$'\t'"${f}"
    if [ -n "${group_lines[$key]:-}" ]; then
        group_lines[$key]+=$'\n'"$line"
    else
        group_lines[$key]="$line"
    fi
done

archived=0

for key in "${!group_lines[@]}"; do
    mapfile -t lines < <(printf '%s\n' "${group_lines[$key]}" | sort -V)
    count="${#lines[@]}"
    [ "$count" -gt 1 ] || continue
    for ((i = 0; i < count - 1; i++)); do
        path="${lines[$i]#*$'\t'}"
        dest="${OLD_DIR}/${path##*/}"
        mv -f -- "$path" "$dest"
        success "archived ${path##*/} -> $dest"
        archived=$((archived + 1))
    done
    keep="${lines[$((count - 1))]#*$'\t'}"
    info "keeping ${keep##*/}"
done

if [ "$archived" -eq 0 ]; then
    info "appimage-prune: nothing to archive"
fi
