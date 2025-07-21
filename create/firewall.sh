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
		read -rp "$1 [Y/n]: " yn
		case "$yn" in
		[Yy]* | "") return 0 ;;
		[Nn]*) return 1 ;;
		*) echo "Please answer y or n." ;;
		esac
	done
}

# ---- sudo Privilege Check ----
if [[ "$EUID" -ne 0 ]]; then
	err "This script must be run as root."
	exit 1
fi

# ---- SSH Port Setup ----
SSH_PORT=22
if confirm "Use the default SSH port (22)?"; then
	log "Using default SSH port: $SSH_PORT"
else
	read -rp "Enter new SSH port: " CUSTOM_PORT
	if [[ -z "$CUSTOM_PORT" || ! "$CUSTOM_PORT" =~ ^[0-9]+$ ]]; then
		err "Invalid port input. Aborting."
		exit 1
	fi
	SSH_PORT="$CUSTOM_PORT"
	log "Using custom SSH port: $SSH_PORT"
fi

# ---- UFW Installation Check ----
if command -v ufw &>/dev/null && ufw --version &>/dev/null; then
	success "UFW is already installed. Version: $(ufw --version | head -n1)"
else
	log "Installing UFW (Uncomplicated Firewall)..."
	apt update && apt install -y ufw
fi

# ---- UFW Configuration ----
log "Setting default firewall policies..."
ufw default deny incoming
ufw default allow outgoing

# Confirm adding SSH rule
if confirm "Add SSH firewall rule on port $SSH_PORT? This may lock you out if incorrect"; then
	log "Allowing SSH on port $SSH_PORT"
	ufw allow "$SSH_PORT/tcp" comment "SSH access"
else
	err "User aborted firewall setup at SSH rule step."
	exit 1
fi

log "Allowing HTTP (80) and HTTPS (443)"
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"

log "Firewall rules set (not yet enabled). Current rules:"
ufw status numbered

# Confirm enabling firewall
if confirm "Enable UFW firewall now? This will apply all rules and may lock you out if SSH port rules are incorrect"; then
	log "Enabling firewall (will remain enabled across reboots)..."
	ufw --force enable
else
	err "User aborted firewall setup at enable step."
	exit 1
fi

success "Firewall status (rules applied):"
ufw status verbose

success "UFW firewall setup complete!"
