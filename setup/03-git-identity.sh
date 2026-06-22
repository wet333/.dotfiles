#!/usr/bin/env bash
#
# setup/03-git-identity.sh - Configure global git identity and defaults from .env.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"

detect_os
load_env

# --- Settings ----------------------------------------------------------------
GIT_NAME="${GIT_NAME:-}"
GIT_EMAIL="${GIT_EMAIL:-}"
GIT_EDITOR="${GIT_EDITOR:-vim}"
GIT_DEFAULT_BRANCH="${GIT_DEFAULT_BRANCH:-master}"

have git || { error "git is not installed; run 01-core-packages.sh or bootstrap first."; exit 1; }

# Skip if identity is missing or still the template placeholders.
if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ] \
   || [ "$GIT_NAME" = "Your Name" ] || [ "$GIT_EMAIL" = "you@example.com" ]; then
    warning "GIT_NAME/GIT_EMAIL not set in $DOTFILES/.env; skipping git identity."
    exit 0
fi

# --- Identity & defaults -----------------------------------------------------
log "Configuring global git identity and defaults..."

git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch "$GIT_DEFAULT_BRANCH"
git config --global pull.rebase false
git config --global core.editor "$GIT_EDITOR"
git config --global color.ui auto

# --- Aliases -----------------------------------------------------------------
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --decorate --all"

success "Git configured for $GIT_NAME <$GIT_EMAIL>."
