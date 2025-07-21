# Scripts

This repo contains a collection of scripts for system setup, deployment, and automation.

## Repo structure:

```sh
root
├── <action>
│   ├── <script_1>.sh
│   ├── <script_2>.sh
└── <action>
    └── <script>.sh
```

## Usage

- Use the following command as a blueprint of how to reference and execute a script.

### Inline

- Pass the new username as an argument

```sh
curl -fsSL https://raw.githubusercontent.com/Configology/scripts/master/<action>/<script>.sh | sudo bash -s -- <some_argument>
```

### Interactive

- Download and run the file interactively

```sh
curl -O https://raw.githubusercontent.com/Configology/scripts/master/<action>/<script>.sh
chmod +x <script>.sh
sudo ./<script>.sh
```

## Actions

### install/

_Adding dependencies or packages_

- `install/docker.sh`: Installs Docker Engine on Ubuntu LTS

### create/

_Creating a new resource_

- `create/sudo_user.sh`: Creates a new user with sudo privileges and public SSH keys from root on Ubuntu LTS
- `create/firewall.sh`: Creates a VPS firewall using [Uncomplicated Firewall](https://help.ubuntu.com/community/UFW)
- `create/rate_limiter.sh`: Mitigate brute force attacks by setting up [Fail2Ban](https://github.com/fail2ban/fail2ban?tab=readme-ov-file)
