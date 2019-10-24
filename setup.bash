


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


