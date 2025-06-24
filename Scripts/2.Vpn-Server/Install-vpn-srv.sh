#!/bin/bash
PKISERVER=pki.rma-dev.ru
#copy the private ssh data
cat >> ~/.ssh/id_rsa <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBFxHSpdZqdzEdNPC25S81viEh65lwNLwcKRN703KULIwAAAJC4usAEuLrA
BAAAAAtzc2gtZWQyNTUxOQAAACBFxHSpdZqdzEdNPC25S81viEh65lwNLwcKRN703KULIw
AAAED6aqi9cZzxa/ytv7td3CGxIzwOA2Kb24YkhCaH5uvRm0XEdKl1mp3MR008LblLzW+I
SHrmXA0vBwpE3vTcpQsjAAAADW1yQEFLUy1JVC1TQzY=
-----END OPENSSH PRIVATE KEY-----
EOF
sudo chmod 700 ~/.ssh/id_rsa
sudo apt update && sudo apt-get install easy-rsa openvpn iptables-persistent -y
sudo mkdir -p /opt/easy-rsa
sudo mkdir -p /opt/openvpn
sudo ln -s /usr/share/easy-rsa/* /opt/easy-rsa/
sudo ln -s /etc/openvpn/* /opt/openvpn/
sudo chown -R $USER:$USER /opt/easy-rsa
sudo chown -R $USER:$USER /opt/openvpn
cd /opt/easy-rsa
./easyrsa init-pki
./easyrsa gen-req server nopass
#Enter the CN name ( vpn.rma-decdv.ru)
#Private-Key and Public-Certificate-Request files created.Your files are:
#req: /opt/easy-rsa/pki/reqs/server.req - public ( send to pki srv for sign)
#key: /opt/easy-rsa/pki/private/server.key -public(dont send any)
mkdir /opt/openvpn/certs
#copy req server.req to PKI for sign
scp /opt/easy-rsa/pki/reqs/server.req $PKISERVER:/opt/easy-rsa/pki/reqs/
openvpn --genkey secret /opt/openvpn/certs/ta.key
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /opt/openvpn/server
sudo chown -R $USER:$USER /opt/openvpn/server/server.conf
#vim server.conf
#ca /opt/openvpn/certs/ca.crt
#cert /opt/openvpn/certs/server.crt
#key /opt/easy-rsa/pki/private/server.key  # This file should be kept secret
#dh none
#user nobody
#group nogroup

sudo sed -i "$ a net.ipv4.ip_forward = 1" /etc/sysctl.conf
INTERFACE=$(ip route show default | awk '/default/ {print $5}')
sudo iptables -A INPUT -i $INTERFACE -m state --state NEW -p "udp" --dport 1194 -j ACCEPT
sudo iptables -A INPUT -i tun+ -j ACCEPT
sudo iptables -A FORWARD -i tun+ -j ACCEPT
sudo iptables -A FORWARD -i tun+ -o $INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $INTERFACE -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $INTERFACE -j MASQUERADE
sudo netfilter-persistent save
sudo systemctl enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service
sudo systemctl status openvpn-server@server.service
