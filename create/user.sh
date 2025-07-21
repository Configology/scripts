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

# ---- Root Privilege Check ----
if [[ "$EUID" -ne 0 ]]; then
	err "This script must be run as root."
	exit 1
fi

# ---- Username Input ----
# Check if a username was passed as the first argument
USERNAME="${1:-}"
if [[ -z "$USERNAME" ]]; then
	read -rp "Enter new username: " USERNAME
fi

# ---- Username Validation ----
# Validate that the username is not empty and only contains valid characters
if [[ -z "$USERNAME" || "$USERNAME" =~ [^a-zA-Z0-9_-] || "$USERNAME" == -* || "$USERNAME" == "root" ]]; then
	err "Invalid username: '$USERNAME'"
	exit 1
fi
# Check if the user already exists in the system
if id "$USERNAME" &>/dev/null; then
	err "User '$USERNAME' already exists."
	exit 1
fi

# ---- User Creation ----
# Create the user with no GECOS (full name, room number, etc.)
log "Creating new user: $USERNAME"
adduser --gecos "" "$USERNAME"

# ---- Sudo Privileges Prompt ----
if confirm "Grant sudo privileges to $USERNAME?"; then
	log "Granting sudo privileges to $USERNAME"
	usermod -aG sudo "$USERNAME"
else
	log "Skipping sudo privileges for $USERNAME"
fi

# ---- SSH Key Setup ----
ROOT_SSH_DIR="/root/.ssh"
USER_HOME="/home/$USERNAME"
if [[ -d "$ROOT_SSH_DIR" ]]; then
	if confirm "Copy root's SSH keys to $USERNAME?"; then
		log "Copying SSH keys from root to $USERNAME"
		rsync --archive --chown="$USERNAME:$USERNAME" "$ROOT_SSH_DIR" "$USER_HOME"
	else
		log "Skipping SSH key copy"
	fi
else
	warn "No SSH keys found in $ROOT_SSH_DIR — skipping key copy"
fi

# ---- Final Output ----
success "User '$USERNAME' created!"
SERVER_IP=$(curl -4 -s https://ifconfig.me || echo "<your_server_ip>")
log "You can now log in as: ssh $USERNAME@$SERVER_IP"
log "Switch to the new user: su - $USERNAME"
if id -nG "$USERNAME" | grep -qw sudo; then
	success "User '$USERNAME' was added to the sudo group."
	log "Verify sudo access after login: sudo ls /"
fi
