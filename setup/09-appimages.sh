#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"
source "$DOTFILES/lib/pkgmanager.sh"

detect_os

APPS_DIR="$HOME/Applications"
OLD_DIR="$APPS_DIR/.old"
PRUNE_SCRIPT="$DOTFILES/scripts/appimage-prune.sh"
UNIT_DIR="$HOME/.config/systemd/user"
PRUNE_PATH_UNIT="$UNIT_DIR/appimage-prune.path"
PRUNE_SERVICE_UNIT="$UNIT_DIR/appimage-prune.service"

user_systemd_ok() {
    [ -n "${XDG_RUNTIME_DIR:-}" ] || return 1
    systemctl --user show-environment >/dev/null 2>&1
}

write_file() {
    local dest="$1" content="$2"
    local tmp
    tmp="$(mktemp)"
    printf '%s\n' "$content" >"$tmp"
    if [ -f "$dest" ] && cmp -s -- "$tmp" "$dest"; then
        rm -f -- "$tmp"
        info "unchanged: $dest"
        return 0
    fi
    mkdir -p -- "$(dirname -- "$dest")"
    mv -f -- "$tmp" "$dest"
    success "wrote $dest"
}

latest_appimaged() {
    shopt -s nullglob
    local candidates=("$APPS_DIR"/appimaged-*.AppImage)
    shopt -u nullglob
    if [ "${#candidates[@]}" -eq 0 ]; then
        return 1
    fi
    printf '%s\n' "${candidates[@]}" | sort -V | tail -n1
}

fuse2_present() {
    shopt -s nullglob
    local libs=(/lib/*/libfuse.so.2 /usr/lib/*/libfuse.so.2 /usr/lib64/libfuse.so.2 /lib64/libfuse.so.2)
    shopt -u nullglob
    [ "${#libs[@]}" -gt 0 ]
}

install_fuse() {
    log "Installing FUSE runtime..."
    if fuse2_present; then
        info "libfuse2 already present; skipping install."
        return 0
    fi
    case "$PKG_MGR" in
        dnf) pkg_install fuse-libs fuse ;;
        apt)
            if pkg_install libfuse2; then
                return 0
            fi
            if pkg_install libfuse2t64; then
                return 0
            fi
            warning "Could not install libfuse2 or libfuse2t64; AppImages may fail to launch."
            ;;
        *)
            warning "Unknown PKG_MGR '$PKG_MGR'; skipping FUSE install."
            ;;
    esac
}

download_appimaged() {
    local arch assets rel dest existing
    if existing="$(latest_appimaged)"; then
        chmod +x -- "$existing"
        info "appimaged already present; skipping download."
        return 0
    fi

    case "$(uname -m)" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        armv7l) arch="armhf" ;;
        i686|i386) arch="i686" ;;
        *)
            warning "Unsupported architecture $(uname -m) for appimaged; skipping download."
            return 0
            ;;
    esac

    have wget || pkg_install wget

    log "Downloading appimaged ($arch)..."
    assets="$(wget -qO- https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous)" || {
        error "Failed to fetch appimaged release index."
        return 1
    }
    rel="$(printf '%s' "$assets" | grep -oE "/probonopd/go-appimage/releases/download/continuous/appimaged-[^\"]+-${arch}\\.AppImage" | head -n1 || true)"
    if [ -z "$rel" ]; then
        error "Could not find appimaged AppImage for $arch."
        return 1
    fi
    dest="$APPS_DIR/$(basename -- "$rel")"
    tmp="${dest}.part"
    wget -c -O "$tmp" "https://github.com${rel}"
    mv -f -- "$tmp" "$dest"
    chmod +x -- "$dest"
    success "Downloaded $dest"
}

enable_appimaged() {
    local bin
    if ! bin="$(latest_appimaged)"; then
        warning "No appimaged AppImage found; skipping service enable."
        return 0
    fi
    chmod +x -- "$bin"

    if ! user_systemd_ok; then
        warning "No user systemd bus; launch $bin after login to register appimaged.service."
        return 0
    fi

    if [ ! -f "$HOME/.config/systemd/user/appimaged.service" ]; then
        log "Launching appimaged to register the user service..."
        "$bin" >/dev/null 2>&1 &
        local pid=$!
        for _ in {1..15}; do
            if [ -f "$HOME/.config/systemd/user/appimaged.service" ]; then
                break
            fi
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    fi

    systemctl --user daemon-reload
    if systemctl --user enable --now appimaged.service; then
        success "appimaged.service enabled."
    else
        warning "Could not enable appimaged.service; start it after login."
    fi
}

install_prune_units() {
    write_file "$PRUNE_PATH_UNIT" "[Unit]
Description=Watch ~/Applications and prune old AppImage versions
[Path]
PathChanged=%h/Applications
Unit=appimage-prune.service
[Install]
WantedBy=default.target"

    write_file "$PRUNE_SERVICE_UNIT" "[Unit]
Description=Prune old AppImage versions (keep latest, archive rest)
[Service]
Type=oneshot
ExecStart=/usr/bin/env bash ${PRUNE_SCRIPT}"

    if ! user_systemd_ok; then
        warning "No user systemd bus; enable appimage-prune.path after login."
        return 0
    fi

    systemctl --user daemon-reload
    if systemctl --user enable --now appimage-prune.path; then
        success "appimage-prune.path enabled."
    else
        warning "Could not enable appimage-prune.path; start it after login."
    fi
}

log "Setting up AppImage integration..."

mkdir -p -- "$APPS_DIR" "$OLD_DIR"
chmod +x -- "$PRUNE_SCRIPT"

install_fuse
download_appimaged
enable_appimaged
install_prune_units

link_file "$PRUNE_SCRIPT" "$HOME/.local/bin/appimage-prune"
bash "$PRUNE_SCRIPT"

warning "A re-login (or restart of the desktop session) may be needed before new apps appear in the menu."
warning "appimaged also watches ~/Downloads, /opt, ~/.local/bin and directories on PATH."

success "AppImage setup complete."
