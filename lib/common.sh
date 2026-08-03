#!/usr/bin/env bash
#
# lib/common.sh - Shared helpers (logging, env, symlinks) for install.sh and setup/.
# Sourced, not executed. Safe to source multiple times.

# --- Logging -----------------------------------------------------------------

_c_reset=$'\e[0m'
_c_blue=$'\e[1;34m'
_c_green=$'\e[1;32m'
_c_yellow=$'\e[1;33m'
_c_red=$'\e[1;31m'
_c_gray=$'\e[1;90m'

log()     { printf '%s[LOG ]%s %s\n' "$_c_gray"   "$_c_reset" "$*"; }
info()    { printf '%s[INFO]%s %s\n' "$_c_blue"   "$_c_reset" "$*"; }
success() { printf '%s[OK  ]%s %s\n' "$_c_green"  "$_c_reset" "$*"; }
warning() { printf '%s[WARN]%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2; }
error()   { printf '%s[ERR ]%s %s\n' "$_c_red"    "$_c_reset" "$*" >&2; }

# --- Predicates --------------------------------------------------------------

# have <cmd> - true if the command exists on PATH.
have() { command -v "$1" >/dev/null 2>&1; }

# --- Privilege escalation ----------------------------------------------------

# Authenticate for sudo, and maintain sudo until the end of script.
# Usage: ensure_sudo
ensure_sudo() {
    have sudo || return 0

    sudo -v

    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done &                  # Starts new background process

    SUDO_KEEPALIVE_PID=$!   # Saves sudo process id
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT
}

# --- Configuration -----------------------------------------------------------

# Export KEY=value pairs from an env file (default $DOTFILES/.env) so child processes inherit them.
# Usage: load_env [file] | Example: load_env ~/.dotfiles/.env
load_env() {
    local f="${1:-${DOTFILES:-.}/.env}"
    [ -f "$f" ] || return 0
    set -a
    . "$f"
    set +a
}

# --- File / symlink helpers --------------------------------------------------

# Idempotently symlink src -> dest, backing up an existing dest to dest.bak.
# Usage: link_file <src> <dest> | Example: link_file "$DOTFILES/.bashrc" "$HOME/.bashrc"
link_file() {
    local src="$1" dest="$2"

    if [ ! -e "$src" ]; then
        error "link_file: source does not exist: $src"
        return 1
    fi

    mkdir -p "$(dirname "$dest")"

    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
        info "already linked: $dest"
        return 0
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        local backup="${dest}.bak"
        warning "backing up existing $dest -> $backup"
        mv -f "$dest" "$backup"
    fi

    ln -s "$src" "$dest"
    success "linked $dest -> $src"
}

# Keep <content> inside a guarded, replaceable block in <file> (idempotent).
# Usage: ensure_block <file> <marker> <content> | Example: ensure_block ~/.bashrc fnm 'eval "$(fnm env)"'
ensure_block() {
    local file="$1" marker="$2" content="$3"
    local open="# >>> ${marker} >>>"
    local close="# <<< ${marker} <<<"

    touch "$file"

    if grep -qF "$open" "$file"; then
        local tmp
        tmp="$(mktemp)"
        awk -v o="$open" -v c="$close" '
            $0==o {skip=1}
            skip==0 {print}
            $0==c {skip=0}
        ' "$file" > "$tmp"
        mv "$tmp" "$file"
    fi

    {
        printf '%s\n' "$open"
        printf '%s\n' "$content"
        printf '%s\n' "$close"
    } >> "$file"
}

# Copy src to dest iff the contents differ (byte-for-byte). If dest already has
# the same bytes, do nothing so mtimes are preserved. If dest differs, the old
# dest is moved aside to <dest>.bak before the new content is laid down.
# Usage: copy_replace <src> <dest> | Example: copy_replace "$DOTFILES/ai/config/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
copy_replace() {
    local src="$1" dest="$2"

    if [ ! -e "$src" ]; then
        error "copy_replace: source does not exist: $src"
        return 1
    fi

    mkdir -p -- "$(dirname -- "$dest")"

    if [ -f "$dest" ] && cmp -s -- "$src" "$dest" 2>/dev/null; then
        info "copy_replace: unchanged: $dest"
        return 0
    fi

    if [ -e "$dest" ]; then
        local backup="${dest}.bak"
        warning "copy_replace: backing up $dest -> $backup"
        mv -f -- "$dest" "$backup"
    fi

    cp -f -- "$src" "$dest"
    success "copy_replace: copied $src -> $dest"
}

# Mirror a directory tree: every regular file under <src-dir> lands as an
# identical copy under <dest-dir>; any file in <dest-dir> that has no
# counterpart in <src-dir> is moved to <dest-dir>/<path>.bak before being
# removed. Idempotent: re-running is a no-op once the trees match.
# Usage: mirror_dir <src-dir> <dest-dir> | Example: mirror_dir "$DOTFILES/ai/config/shared/skills" "$HOME/.claude/skills"
mirror_dir() {
    local src="$1" dest="$2"

    if [ ! -d "$src" ]; then
        error "mirror_dir: source is not a directory: $src"
        return 1
    fi

    mkdir -p -- "$dest"

    local kept=0 added=0 removed=0
    local src_re="${src}/" dest_re="${dest}/" f rel target backup

    while IFS= read -r f; do
        [ -n "$f" ] || continue
        rel="${f#"$src_re"}"
        target="${dest_re}${rel}"
        if [ -f "$target" ] && cmp -s -- "$f" "$target" 2>/dev/null; then
            kept=$((kept + 1))
            continue
        fi
        mkdir -p -- "$(dirname -- "$target")"
        if [ -e "$target" ]; then
            backup="${target}.bak"
            warning "mirror_dir: backing up $target -> $backup"
            mv -f -- "$target" "$backup"
        fi
        cp -f -- "$f" "$target"
        added=$((added + 1))
    done < <(find "$src" -type f)

    while IFS= read -r f; do
        [ -n "$f" ] || continue
        rel="${f#"$dest_re"}"
        if [ ! -e "${src_re}${rel}" ]; then
            backup="${f}.bak"
            warning "mirror_dir: backing up extra $f -> $backup"
            mv -f -- "$f" "$backup"
            removed=$((removed + 1))
        fi
    done < <(find "$dest" -type f)

    info "mirror_dir: $kept kept, $added added/updated, $removed removed (backed up) - $dest"
}
