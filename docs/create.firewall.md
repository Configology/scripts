# Create Firewall

_Standard Ports_

- Port 22: OpenSSH
- Port 80: HTTP
- Port 443: HTTPS

_Docker_

- Exposing a port from a container overrides the `ufw` firewall
- One workaround is to just not expose these ports in Docker compose, and use a reverse proxy to route traffic

## Automated Script

```sh
sudo curl -fsSL -o /usr/local/sbin/create-firewall https://raw.githubusercontent.com/Configology/scripts/master/create/firewall.sh && \
sudo chmod +x /usr/local/sbin/create-firewall && \
sudo create-firewall
```

## Manual Steps

**Uncomplicated Firewall**

1. Install UFW. (Should be pre-installed on Ubuntu)

```sh
sudo apt install ufw
```

2. Prevent incoming traffic

```sh
sudo ufw default deny incoming
```

3. Allow all outgoing traffic

```sh
sudo ufw default allow outgoing
```

4. Enable inbound requests to necessary ports

```sh
sudo ufw allow OpenSSH    # SSH
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
```

5. Optional: Update to a custom SSH port

```sh
sudo ufw allow <new_port>
```

6. Verify additions

```sh
sudo ufw show added
```

7. Enable firewall

```sh
sudo ufw enable
```

8. Verify firewall active

```sh
sudo ufw status
```

## Resources

[DigitalOcean Tutorial](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu)
