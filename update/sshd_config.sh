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

# ---- SSH Configuration Files ----
SSH_CONFIG_FILE="/etc/ssh/sshd_config"
SSH_BACKUP_FILE="${SSH_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

log "Creating backup of SSH configuration: $SSH_BACKUP_FILE"
cp "$SSH_CONFIG_FILE" "$SSH_BACKUP_FILE"

# ---- SSH Hardening Configurations ----
declare -A ssh_hardening_configs=(
	["AllowAgentForwarding"]="no"
	["AllowTcpForwarding"]="no"
	["GSSAPIAuthentication"]="no"
	["KerberosAuthentication"]="no"
	["LoginGraceTime"]="20"
	["MaxAuthTries"]="6"
	["PasswordAuthentication"]="no"
	["PermitEmptyPasswords"]="no"
	["PermitRootLogin"]="no"
	["PermitTunnel"]="no"
	["PermitUserEnvironment"]="no"
	["UsePAM"]="no"
	["X11Forwarding"]="no"
)

log "Applying SSH hardening configurations..."
for key in "${!ssh_hardening_configs[@]}"; do
	val="${ssh_hardening_configs[$key]}"

	if grep -qE "^[[:space:]]*#*[[:space:]]*${key}[[:space:]]+" "$SSH_CONFIG_FILE"; then
		sed -i -E "s|^[[:space:]]*#*[[:space:]]*${key}[[:space:]]+.*|${key} ${val}|" "$SSH_CONFIG_FILE"
		action="Updated"
	else
		echo "${key} ${val}" >>"$SSH_CONFIG_FILE"
		action="Appended"
	fi

	final_line=$(grep -E "^${key}[[:space:]]+" "$SSH_CONFIG_FILE" | head -n1)
	log "${action}: ${final_line}"
done

# ---- Comment out AcceptEnv lines ----
if grep -q '^AcceptEnv' "$SSH_CONFIG_FILE"; then
	sed -i 's/^AcceptEnv/#AcceptEnv/' "$SSH_CONFIG_FILE"
	log "Commented out AcceptEnv line:"
	log "$(grep -E "^#AcceptEnv" "$SSH_CONFIG_FILE" | head -n1)"
fi

# ---- Validate SSH configuration ----
log "Validating SSH configuration..."
mkdir -p /run/sshd
if ! sshd -t; then
	err "SSH configuration validation failed, restoring backup..."
	cp "$SSH_BACKUP_FILE" "$SSH_CONFIG_FILE"
	exit 1
fi

# ---- Restart SSH ----
log "Restarting SSH service..."
if ! systemctl restart ssh; then
	err "Failed to restart SSH service"
	warn "Configuration changes applied but service restart failed"
	warn "You may need to manually restart SSH: systemctl restart ssh"
	exit 1
fi

# ---- Final Output ----
CURRENT_USER=$(logname 2>/dev/null || whoami)
SERVER_IP=$(curl -4 -s https://ifconfig.me || echo "<your_server_ip>")

success "SSH hardening completed!"
warn "IMPORTANT: Password authentication is now disabled"
warn "Ensure you have SSH key access before closing this session"
warn "Test the configuration in a separate terminal:"
log "ssh ${CURRENT_USER}@${SERVER_IP}"
success "Backup file: $SSH_BACKUP_FILE"
