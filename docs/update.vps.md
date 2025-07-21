# Update & Upgrade VPS

## Automated Installation

```sh
sudo curl -fsSL -o /usr/local/sbin/update-vps https://raw.githubusercontent.com/Configology/scripts/master/update/vps.sh && \
sudo chmod +x /usr/local/sbin/update-vps && \
sudo update-vps
```

## Manual Installation

Install updates and upgrade

### Prerequisites Setup

1. Update package list

```sh
export DEBIAN_FRONTEND=noninteractive
apt-get -y \
	-o Dpkg::Options::="--force-confdef" \
	-o Dpkg::Options::="--force-confold" \
	upgrade

```
