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

log "Installing Fail2Ban..."
apt update && apt install -y fail2ban

# ---- Setup jail.local ----
JAIL_CONF="/etc/fail2ban/jail.conf"
JAIL_LOCAL="/etc/fail2ban/jail.local"

if [[ ! -f "$JAIL_LOCAL" ]]; then
	success "Creating jail.local from jail.conf"
	cp "$JAIL_CONF" "$JAIL_LOCAL"
else
	log "jail.local already exists — skipping copy"
fi

# ---- Ensure 'enabled = true' exists in actual [sshd] config block ----
if grep -q "^\[sshd\]" "$JAIL_LOCAL"; then
	log "Found actual [sshd] section — ensuring 'enabled = true' is set"

	# Replace existing enabled line in the block
	sed -i '/^\[sshd\]/,/^\[.*\]/s/^\s*enabled\s*=.*/enabled = true/' "$JAIL_LOCAL"

	# Insert enabled = true if not present
	if ! sed -n '/^\[sshd\]/,/^\[.*\]/p' "$JAIL_LOCAL" | grep -q "^\s*enabled\s*="; then
		sed -i '/^\[sshd\]/a enabled = true' "$JAIL_LOCAL"
	fi
else
	log "No [sshd] section found — creating it with 'enabled = true'"
	echo -e "\n[sshd]\nenabled = true" >>"$JAIL_LOCAL"
fi

# ---- Restart Fail2Ban ----
log "Restarting Fail2Ban..."
systemctl restart fail2ban
systemctl enable --now fail2ban

# ---- Status Check ----
log "Checking Fail2Ban service and SSH jail status..."
fail2ban-client status || err "Fail2Ban is not running properly"
fail2ban-client status sshd || warn "SSHD jail status not available — check manually"

# ---- Final Notes ----
success "Fail2Ban setup complete!"
echo -e "To check jail status later: \n  sudo fail2ban-client status sshd"
