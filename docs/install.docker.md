# Docker Setup on Ubuntu

- Install and configure Docker Community Edition on Ubuntu server.

## Automated Installation

```sh
sudo curl -fsSL -o /usr/local/sbin/install-docker https://raw.githubusercontent.com/Configology/scripts/master/install/docker.sh && \
sudo chmod +x /usr/local/sbin/install-docker && \
sudo install-docker
```

## Manual Installation

**Install Docker from official repository for latest version**

### Prerequisites Setup

1. Update package list

```sh
sudo apt update && sudo apt upgrade -y
```

2. Install prerequisite packages for HTTPS repositories

```sh
sudo apt install apt-transport-https ca-certificates curl software-properties-common
```

3. Add Docker GPG key

```sh
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

4. Add Docker repository to APT sources

```sh
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
```

5. Verify installation source (should show Docker repo, not Ubuntu default)

```sh
apt-cache policy docker-ce
```

### Docker Installation

1. Install Docker Community Edition

```sh
sudo apt install docker-ce
```

2. Verify Docker service status

```sh
sudo systemctl status docker
```

## Configuration

**Optional: Run Docker commands without sudo**

### User Group Setup

1. Add current user to docker group

```sh
sudo usermod -aG docker ${USER}
```

2. Apply group membership (re-login or run)

```sh
su - ${USER}
```

3. Verify group membership

```sh
groups
```

4. Add specific user to docker group (if needed)

```sh
sudo usermod -aG docker <user_name>
```

## Resources

https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
