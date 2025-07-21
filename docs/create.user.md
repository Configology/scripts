# Create User

## Automated Script

```sh
sudo curl -fsSL -o /usr/local/sbin/create-user https://raw.githubusercontent.com/Configology/scripts/master/create/user.sh && \
sudo chmod +x /usr/local/sbin/create-user && \
sudo create-user
```

## Manual Steps

1. Login as root

```sh
ssh root@<server_ip_address>
```

2. Add a new user account

```sh
adduser <new_user>
```

3. Create a password for new user

4. Grant new user `sudo` permissions

```sh
usermod -aG sudo <new_user>
```

5. Copy SSH public key to new user. (Keys, permissions, timestamps, etc.)

```sh
rsync --archive --chown=<new_user>:<new_user> /root/.ssh /home/<new_user>/
```

6. Switch to new user

```sh
su - <new_user>
```

7. Verify `sudo` privileges

```sh
sudo ls /
```

8. Test new user server access

```sh
ssh <new_user>@<server_ip_address>
```
