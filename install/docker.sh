#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status (-e)
# Treat unset variables as an error (-u)
# Return the exit code of the rightmost command in a pipeline that fails (-o pipefail)
set -euo pipefail

# ---- Logging Helpers ----
# ANSI color codes for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'

log() { echo -e "${BLUE}[INFO]${NO_COLOR} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NO_COLOR} $*"; }
warn() { echo -e "${YELLOW}[WARNING]${NO_COLOR} $*"; }
err() { echo -e "${RED}[ERROR]${NO_COLOR} $*" >&2; }
confirm() {
	while true; do
		read -rp "$1 [y/N]: " yn
		case "$yn" in
		[Yy]*) return 0 ;;
		[Nn]* | "") return 1 ;;
		*) echo "Please answer y or n." ;;
		esac
	done
}

# ---- sudo Privilege Check ----
if [[ "$EUID" -ne 0 ]]; then
	err "This script must be run as root or with sudo privileges"
	exit 1
fi

# Detect if Docker is already installed and working
if command -v docker &>/dev/null && docker --version &>/dev/null; then
	success "Docker is already installed. Version: $(docker --version | awk '{print $3}' | sed 's/,//')"
	exit 0
fi

log "Installing dependencies..."
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

log "Adding Docker’s official GPG key..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)

log "Adding Docker APT repository..."
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" |
	tee /etc/apt/sources.list.d/docker.list >/dev/null

log "Updating package index again..."
apt update

log "Install Docker Community Edition"
apt install -y containerd.io docker-ce docker-ce-cli

# ---- Docker Swarm Setup (Optional) ----
if confirm "Initialize Docker Swarm on this node?"; then
	log "Detecting network interface and IP address..."

	# Get the primary IP address (usually the one with default route)
	PRIMARY_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')

	if [[ -z "$PRIMARY_IP" ]]; then
		warn "Could not auto-detect primary IP address"
		log "Available IP addresses:"
		ip addr show | grep -E 'inet [0-9]' | grep -v '127.0.0.1' | awk '{print "  " $2}' | cut -d'/' -f1

		while true; do
			read -rp "Enter the IP address to advertise: " MANUAL_IP
			if [[ "$MANUAL_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
				PRIMARY_IP="$MANUAL_IP"
				break
			else
				err "Invalid IP address format. Please try again."
			fi
		done
	fi

	log "Using IP address: $PRIMARY_IP"
	log "Initializing Docker Swarm..."

	if docker swarm init --advertise-addr "$PRIMARY_IP"; then
		success "Docker Swarm initialized successfully!"
		log "Manager join token:"
		docker swarm join-token manager
		log ""
		log "Worker join token:"
		docker swarm join-token worker
	else
		err "Failed to initialize Docker Swarm"
		exit 1
	fi
else
	log "Skipping Docker Swarm initialization"
fi

log "Checking Docker service status..."
if systemctl is-active --quiet docker; then
	success "Docker service is running"
else
	warn "Docker service is NOT running"
fi

log "Adding user '${SUDO_USER:-$USER}' to docker group..."
getent group docker >/dev/null || groupadd docker
usermod -aG docker "${SUDO_USER:-$USER}"

# Activate docker group for current session if running via sudo
if [[ -n "${SUDO_USER:-}" ]]; then
	log "Activating docker group permissions..."
	sudo -u "$SUDO_USER" newgrp docker
fi

success "Installation complete!"
log "Log out and back in (or run 'newgrp docker') to activate Docker group permissions."
log "Test Docker with: docker run hello-world"
