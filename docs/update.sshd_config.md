# Update SSHD Defaults

## Automated Installation

```sh
sudo curl -fsSL -o /usr/local/sbin/update-sshd_config https://raw.githubusercontent.com/Configology/scripts/master/update/sshd_config.sh && \
sudo chmod +x /usr/local/sbin/update-sshd_config && \
sudo update-sshd_config
```

## Harden Authentication

_Update Configuration Defaults_

1. Open SSH configuration file

```sh
sudo vim /etc/ssh/sshd_config
```

2. Update the following entries

- Prevent a potential attacker from logging into your server directly as root

```sh
PermitRootLogin no
```

- Remove brute force password guessing

```sh
PasswordAuthentication no
PermitEmptyPasswords no
```

- limit the maximum number of authentication attempts for a particular login session

```sh
MaxAuthTries 3
```

_Make sure to setup [1Password](https://gist.github.com/solobroneur/4c1414553a0e71e40e16852898c7300e#setup-1password) agent properly to avoid getting locked out_

- Reduce amount of time a user has to complete authentication after initially connecting to your SSH server. Helps with Denial-of-Service attacks

```sh
LoginGraceTime 20
```

- Remove additional authentication methods

```sh
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
UsePAM no
```

3. Save the file

4. Test SSH with new configuration before logging out

```sh
ssh <new_user>@<server_ip_address>
```

## Update Default Configuration

1. Open SSH configuration file

```sh
sudo vim /etc/ssh/sshd_config
```

2. Update the following entries

- Disable the following if you are not running a graphical environment on your server:

```sh
X11Forwarding no
```

- OpenSSH server allows connecting clients to pass custom environment variables

```sh
PermitUserEnvironment no

# Also comment out references to `AcceptEnv`
```

- miscellaneous options related to tunneling and forwarding

```sh
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
```

- Disable banner which may expose sensitive information

```sh
DebianBanner no
```

## Verify Configuration Changes

1. Verify the configuration file has valid syntax

```sh
sudo sshd -t
```

2. Apply SSH configuration changes

```sh
sudo systemctl restart ssh.service
```
