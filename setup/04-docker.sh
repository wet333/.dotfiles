#!/usr/bin/env bash
#
# setup/04-docker.sh - Install Docker CE (engine, CLI, containerd, buildx, compose), enable the service and add $USER to the docker group.
# The docker-group change requires a re-login (or `newgrp docker`) to take effect.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"
source "$DOTFILES/lib/os.sh"
source "$DOTFILES/lib/pkgmanager.sh"

detect_os

DOCKER_PKGS="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

# Add Docker's official repo for the dnf (Fedora) family.
# Usage: setup_docker_repo_dnf
# Fetch the .repo file directly: it works on both dnf4 and dnf5 (Nobara), whose config-manager syntaxes differ.
setup_docker_repo_dnf() {
    sudo dnf -y install dnf-plugins-core
    sudo curl -fsSL https://download.docker.com/linux/fedora/docker-ce.repo \
        -o /etc/yum.repos.d/docker-ce.repo
}

# Add Docker's official repo for the apt (Debian/Ubuntu) family.
# Usage: setup_docker_repo_apt
setup_docker_repo_apt() {
    local slug arch codename
    case "$OS_ID" in
        debian) slug="debian" ;;
        *)      slug="ubuntu" ;;
    esac

    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL "https://download.docker.com/linux/$slug/gpg" \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    arch="$(dpkg --print-architecture)"
    codename="$(. /etc/os-release && echo "${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}")"
    echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$slug $codename stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update -y
}

# --- Install -----------------------------------------------------------------
if pkg_installed docker-ce; then
    info "docker-ce already installed; skipping repo setup and install."
else
    log "Setting up Docker's official repository..."
    case "$PKG_MGR" in
        dnf) setup_docker_repo_dnf ;;
        apt) setup_docker_repo_apt ;;
    esac
    log "Installing Docker packages..."
    # shellcheck disable=SC2086
    pkg_install $DOCKER_PKGS
fi

# --- Service -----------------------------------------------------------------
log "Enabling the docker service..."
enable_service docker

# --- Rootless usage: docker group --------------------------------------------
log "Adding $USER to the 'docker' group..."
if ! getent group docker >/dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker "$USER"
warning "Log out and back in (or run 'newgrp docker') for the group change to take effect."

success "Docker setup complete."
