#!/bin/bash


STATIC_IP=$(hostname -I | awk '{print $1}')/16
SSH_PORT=5050

# update and upgrade packages

apt update -y
apt upgrade -y


# set static ip

rm -f /etc/netplan/*
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
" > /etc/netplan/static-config.yaml

netplan apply
systemctl restart systemd-networkd

# set firewall rules

ufw --force disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw limit $(SSH_PORT)/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable


# set SSH configuration
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.origine
echo "
# Roger configuration
Port $(SSH_PORT)
PasswordAuthentication no
PubKeyAuthentication yes
PermitRootLogin no


ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  /usr/lib/openssh/sftp-server
" > /etc/ssh/sshd_config
service ssh restart

# config fail2ban
apt install fail2ban -y
apt install apache2 -y

echo "
[sshd]
enabled  = true
port     = $(SSH_PORT)
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath   = /var/log/apache2/access.log
maxRetry = 30
findtime = 30
bantime = 60

[portscan]
enabled  = true
filter   = portscan
logpath  = /var/log/ufw.log
action   = ufw
maxretry = 5
ignoreip = 10.12.254.254"

echo "
[Definition]
failregex = ^<HOST> -.*\"(GET|POST).*
ignoreregex =" > http-get-dos.conf

echo "
[Definition]
failregex = UFW BLOCK.* SRC=<HOST>
ignoreregex =" > portscan.conf

fail2ban-client restart
service fail2ban restart



# setup crontab jobs

echo "
#!/bin/bash

date >> /var/log/update_script.log
apt update -y >> /var/log/update_script.log
apt upgrade -y >> /var/log/update_script.log
" > /etc/cron.d/update.bash

echo "
#!/bin/bash

OLD=$(cat /etc/cronsum)
NEW=$(md5sum /etc/crontab | awk '{print $1}')

[ ! -e /etc/crontab ] && exit

if [ ! -e /etc/cronsum ]
then
	echo $NEW > /etc/cronsum
	exit
fi

if [ $OLD != $NEW ]
then
	mail -s 'Crontab file has been changed' root@roger <<< 'crontab file has changed.'
	echo $NEW > /etc/cronsum
fi" > /etc/cron.d/checker.bash

crontab -l | { cat; echo -e "@reboot bash /etc/cron.d/update.bash"; } | crontab -
crontab -l | { cat; echo -e "0 4 * * 1 bash /etc/cron.d/update.bash"; } | crontab -
crontab -l | { cat; echo -e "0 0 * * * bash /etc/cron.d/checker.bash"; } | crontab -
