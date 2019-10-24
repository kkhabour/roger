


apt -y update
apt -y upgrade

rm -f /etc/netplan/*
STATICIP=$(hostname -I | awk '{print $1}')/16

echo "
network:
    ethernets:
        enp0s3:
            dhcp4: false
            addresses: [$STATICIP]
            gateway4: 10.12.254.254
            nameservers:
                addresses: [10.23.1.253]
    version: 2
" > /etc/netplan/50-cloud-init.yaml

netplan apply
systemctl restart systemd-networkd


cp /etc/ssh/sshd_config /etc/ssh/sshd_config.origine
rm -f /etc/ssh/sshd_config

echo "
# Roger configuration
Port 5050
PasswordAuthentication no
PubKeyAuthentication yes
PermitRootLogin no


ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  /usr/lib/openssh/sftp-server
" >> /etc/ssh/sshd_config
service ssh restart




# Disabling ufw
ufw --force disable

# Resetting ufw
ufw --force reset

# Deny All Incoming Connections
ufw default deny incoming

# Allow All Outgoing Connections
ufw default allow outgoing

# Allow SSH connection/Limit
ufw limit 5050/tcp

# HTTP
ufw allow 80/tcp

# HTTPS
ufw allow 443/tcp

# Enabling ufw
ufw --force enable



apt-get install -y fail2ban
systemctl start fail2ban
systemctl enable fail2ban


echo "
[DEFAULT]

[sshd]
enabled = false

[ssh]
enabled  = true
port     = 5050
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 4
findtime = 20
bantime = 1m
" > /etc/fail2ban/jail.local
service fail2ban restart


