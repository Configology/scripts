#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status (-e)
# Treat unset variables as an error (-u)
# Return the exit code of the rightmost command in a pipeline that fails (-o pipefail)
set -euo pipefail

# ---- Logging Helpers ----
# ANSI color codes for terminal output
BLUE='\033[0;34m'
NO_COLOR='\033[0m'

log() { echo -e "${BLUE}[INFO]${NO_COLOR} $*"; }

if pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null; then
	log "Another apt process is currently running. Exiting to avoid lock conflict."
	exit 1
fi

log "Updating package index and upgrading packages..."
export DEBIAN_FRONTEND=noninteractive
apt update && apt -y \
	-o Dpkg::Options::="--force-confdef" \
	-o Dpkg::Options::="--force-confold" \
	upgrade
