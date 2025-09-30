#!/bin/bash
CERT_AUTH="/opt/openvpn/certs/ca.crt"
CERT_SRV="/opt/openvpn/certs/server.crt"
KEY_SRV="/opt/easy-rsa/pki/private/server.key"
SRV_CONF="/opt/openvpn/server/server.conf"
TLS_AUTH="/opt/openvpn/certs/ta.key"
INTERFACE=$(ip route show default | awk '/default/ {print $5}')
while [ -z $VPNSERVER ]; do
read -p "Please enter IP-Address or Domain Name of this VPN-SERVER " VPNSERVER
done
while [ -z $PKISERVER ]; do
read -p "Please enter IP-Address or Domain Name of PKI-SERVER " PKISERVER
done
while [ -z $PKILOGIN ]; do
read -p "Please enter the login of PKI-SERVER " PKILOGIN
done

while [ -z $SSH_KEY ]; do
SSH_KEY_DEFAULT=id_ed25519
read -p "Please enter the filename of private ssh-key for servers(in the /home/.ssh/ directory[$SSH_KEY_DEFAULT]: " SSH_KEY
SSH_KEY="${SSH_KEY:-$SSH_KEY_DEFAULT}"
done
echo /home/yc-user/.ssh/$SSH_KEY
if [ -s ~/.ssh/$SSH_KEY ] ; then
        chmod 600 ~/.ssh/$SSH_KEY
else
        echo "The file $SSH_KEY not found in the /home/.ssh/ directory"
        exit
fi
sudo debconf-set-selections <<EOF
iptables-persistent iptables-persistent/autosave_v4 boolean true
iptables-persistent iptables-persistent/autosave_v6 boolean true
EOF

sudo apt update && sudo apt-get install easy-rsa openvpn iptables-persistent -y
sudo mkdir -p /opt/easy-rsa /opt/openvpn/certs
sudo ln -s /usr/share/easy-rsa/* /opt/easy-rsa/
sudo ln -s /etc/openvpn/* /opt/openvpn/
sudo chown -R $USER:$USER /opt/easy-rsa /opt/openvpn

/opt/easy-rsa/easyrsa --pki=/opt/easy-rsa/pki --batch init-pki
/opt/easy-rsa/easyrsa --pki=/opt/easy-rsa/pki --batch gen-req server nopass

openvpn --genkey secret /opt/openvpn/certs/ta.key
scp /opt/easy-rsa/pki/reqs/server.req $PKISERVER:/opt/easy-rsa/pki/reqs/
ssh $PKILOGIN@$PKISERVER -t "/opt/easy-rsa/easyrsa --pki=/opt/easy-rsa/pki --batch sign-req server server; scp /opt/easy-rsa/pki/ca.crt /opt/easy-rsa/pki/issued/server.crt $VPNSERVER:/opt/openvpn/certs/"

sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /opt/openvpn/server
sudo chown -R $USER:$USER /opt/openvpn/server/server.conf

sudo sed -i "s|^ca .*|ca $CERT_AUTH|" $SRV_CONF
sudo sed -i "s|^cert .*|cert $CERT_SRV|" $SRV_CONF
sudo sed -i "s|^key .*|key $KEY_SRV|" $SRV_CONF
sudo sed -i "s|^dh .*|dh none|" $SRV_CONF
sudo sed -i "s|^;user .*|user nobody|" $SRV_CONF
sudo sed -i "s|^;group .*|group nogroup|" $SRV_CONF
sudo sed -i "/^key/a\\
tls-crypt $TLS_AUTH\\
cipher AES-256-GCM\\
auth SHA256" "$SRV_CONF"

sudo iptables -A INPUT -i $INTERFACE -m state --state NEW -p "udp" --dport 1194 -j ACCEPT
sudo iptables -A INPUT -i tun+ -j ACCEPT
sudo iptables -A FORWARD -i tun+ -j ACCEPT
sudo iptables -A FORWARD -i tun+ -o $INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $INTERFACE -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $INTERFACE -j MASQUERADE
sudo netfilter-persistent save
sudo sed -i "$ a net.ipv4.ip_forward = 1" /etc/sysctl.conf
sudo sysctl -p

sudo systemctl enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service
sudo systemctl status openvpn-server@server.service
#EXPORTERS:
sudo apt-get install prometheus-node-exporter
wget -P ~/ https://github.com/rinasmichael/Skillbox/raw/refs/heads/main/Scripts/vpn-srv/openvpn_exporter
chmod +x openvpn_exporter
sudo mv ~/openvpn_exporter /usr/bin/openvpn_exporter
sudo cat >> /etc/systemd/system/openvpn_exporter.service <<EOF
[Unit]
Description=Prometheus OpenVPN Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=openvpn_exporter
Group=openvpn_exporter
Type=simple
ExecStart=/usr/bin/openvpn_exporter

[Install]
WantedBy=multi-user.target
EOF
sudo addgroup --system "openvpn_exporter" --quiet
sudo adduser --system --home /usr/share/openvpn_exporter --no-create-home --ingroup "openvpn_exporter" --disabled-password --shell /bin/false "openvpn_exporter"
sudo usermod -a -G openvpn_exporter root
sudo chgrp openvpn_exporter /var/log/openvpn/openvpn-status.log
sudo chmod 660 /var/log/openvpn/openvpn-status.log
sudo chown openvpn_exporter:openvpn_exporter /usr/bin/openvpn_exporter
sudo chmod 755 /usr/bin/openvpn_exporter
sudo systemctl enable openvpn_exporter.service
sudo systemctl start openvpn_exporter.service
