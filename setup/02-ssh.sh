#!/usr/bin/env bash
#
# setup/02-ssh.sh - Install/enable the SSH server and ensure a client key, then print the public key.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"
source "$DOTFILES/lib/pkgmanager.sh"

detect_os
load_env

# Key settings come from the global .env (with sane fallbacks).
SSH_KEY_TYPE="${SSH_KEY_TYPE:-ed25519}"
SSH_KEY_COMMENT="${SSH_KEY_COMMENT:-${GIT_EMAIL:-}}"
SSH_KEY="$HOME/.ssh/id_$SSH_KEY_TYPE"

# --- SSH server --------------------------------------------------------------
log "Installing and enabling the SSH server..."
pkg_install openssh-server

# systemd unit name differs across families.
case "$OS_FAMILY" in
    rhel)   SSHD_SVC="sshd" ;;
    debian) SSHD_SVC="ssh" ;;
    *)      SSHD_SVC="sshd" ;;
esac
enable_service "$SSHD_SVC"

# --- ~/.ssh directory --------------------------------------------------------
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# --- Client key --------------------------------------------------------------
if [ -f "$SSH_KEY" ]; then
    info "SSH key already exists at $SSH_KEY; skipping generation."
else
    log "Generating $SSH_KEY_TYPE SSH key (no passphrase)..."
    ssh-keygen -t "$SSH_KEY_TYPE" -N "" -C "$SSH_KEY_COMMENT" -f "$SSH_KEY"
fi

if [ -f "$SSH_KEY" ]; then
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"
    info "Your public SSH key:"
    cat "$SSH_KEY.pub"
fi

success "SSH setup complete."
