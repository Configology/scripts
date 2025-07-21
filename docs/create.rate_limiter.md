# SSH Rate Limiter

- Rate limit bots attempting to access VPS through SSH tunnel using brute force attacks.

## Automated Script

```sh
sudo curl -fsSL -o /usr/local/sbin/create-rate-limiter https://raw.githubusercontent.com/Configology/scripts/master/create/rate_limiter.sh && \
sudo chmod +x /usr/local/sbin/create-rate-limiter && \
sudo create-rate-limiter
```

## Fail2Ban

**Ban hosts that cause multiple authentication errors**

### Manual Installation

[Ubuntu](https://github.com/fail2ban/fail2ban/wiki/How-to-install-fail2ban-packages#debian--ubuntu)

1. Update OS registry

```sh
sudo apt update
```

2. Upgrade OS registry

```sh
sudo apt upgrade
```

3. Install `fail2ban` package

```sh
sudo apt install fail2ban -y
```

### Setup

1. Copy base configuration for custom overrides

```sh
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

2. Add home IP Address to ignored IPs

```sh
- #ignoreip = 127.0.0.1/8 ::1
+ ignoreip = 127.0.0.1/8 ::1 <my_ip_address>
```

3. Harden SSH Daemon

```sh
[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 3600
findtime = 600
```

4. Check `fail2ban` jail list SSHD configuration

```sh
sudo fail2ban-client status sshd
```

5. Update servers to use jail list

```sh
[some server]
+ enabled = true
```

6. Run `fail2ban` to ban ssh attempts. (Should have started automatically according to Ubuntu installation docs)

```sh
sudo systemctl restart fail2ban
sudo systemctl enable --now fail2ban
```

7. Re-check `fail2ban` jail list status

```sh
sudo fail2ban-client status
```
