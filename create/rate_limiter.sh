#!/usr/bin/env bash

# Safer Fail2Ban setup using jail.d drop-in and robust checks
# - Debian/Ubuntu + systemd only
# - Avoids copying jail.conf; uses /etc/fail2ban/jail.d/ override
# - Idempotent and defensive

set -euo pipefail

# ---- Logging ----
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NO_COLOR='\033[0m'
log() { echo -e "${BLUE}[INFO]${NO_COLOR} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NO_COLOR} $*"; }
warn() { echo -e "${YELLOW}[WARNING]${NO_COLOR} $*"; }
err() { echo -e "${RED}[ERROR]${NO_COLOR} $*" >&2; }

# ---- Preconditions ----
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
	err "Run as root"
	exit 1
fi

# Check OS (Debian/Ubuntu)
if [[ -f /etc/os-release ]]; then
	. /etc/os-release
	case "${ID:-}" in
	debian | ubuntu) : ;;
	*) warn "Non-Debian/Ubuntu detected (${ID:-unknown}). This script is intended for apt-based systems." ;;
	esac
else
	warn "/etc/os-release missing; proceeding assuming Debian/Ubuntu"
fi

# Check systemd availability
if ! command -v systemctl >/dev/null 2>&1; then
	err "systemctl not found; systemd is required"
	exit 1
fi

# ---- Install fail2ban ----
log "Installing Fail2Ban..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
# Remove man-db to avoid install hangs (not needed on servers)
apt-get purge -y man-db || true
apt-get install -y fail2ban

# ---- Configure jail.d override ----
JAIL_D="/etc/fail2ban/jail.d"
SSH_LOCAL="$JAIL_D/sshd.local"
mkdir -p "$JAIL_D"

# Minimal override: enable sshd jail only
if [[ ! -f "$SSH_LOCAL" ]]; then
	log "Creating $SSH_LOCAL"
	cat >"$SSH_LOCAL" <<'EOF'
[sshd]
enabled = true
EOF
else
	log "$SSH_LOCAL already exists — leaving as-is"
fi

# ---- Enable and (re)start service ----
log "Enabling and starting fail2ban service"
systemctl enable --now fail2ban

# Prefer reload if running; otherwise start handled above
if systemctl is-active --quiet fail2ban; then
	systemctl reload fail2ban || systemctl restart fail2ban
fi

# ---- Status and validation ----
log "Fail2Ban overall status:"
if ! fail2ban-client status; then
	err "Fail2Ban status check failed"
fi

# Check for sshd jail existence before querying
if fail2ban-client status 2>/dev/null | awk '/Jail list:/ {print substr($0, index($0,$3)) }' | tr ', ' '\n' | grep -qx 'sshd'; then
	log "SSHD jail status:"
	if ! fail2ban-client status sshd; then
		warn "Could not retrieve sshd jail status"
	fi
else
	warn "sshd jail not found in Jail list. Verify your sshd filter and logs."
fi

success "Fail2Ban setup complete. To view: fail2ban-client status sshd"
