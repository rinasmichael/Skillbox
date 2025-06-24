#!/bin/bash
VPNSERVER=vpn.rma-dev.ru
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
sudo apt-get update && sudo apt install easy-rsa iptables-persistent -y
sudo mkdir /opt/easy-rsa
sudo ln -s /usr/share/easy-rsa/* /opt/easy-rsa/
sudo chown -R $USER:$USER /opt/easy-rsa
cd /opt/easy-rsa
./easyrsa init-pki
#Your newly created PKI dir is:* /opt/easy-rsa/pki
sudo sed -i '/PermitRootLogin\|PermitEmptyPasswords\|PasswordAuthentication\|PubkeyAuthentication/Id' /etc/ssh/sshd_config
sudo bash -c "cat >> /etc/ssh/sshd_config <<EOF
PermitRootLogin No
PasswordAuthentication No
PermitEmptyPasswords No
PubkeyAuthentication yes
EOF
"
#create reqs for create cert pki
read -p "Enter EASYRSA_REQ_COUNTRY var: " EASYRSA_REQ_COUNTRY
read -p "Enter EASYRSA_REQ_PROVINCE var: " EASYRSA_REQ_PROVINCE
read -p "Enter EASYRSA_REQ_CITY var: " EASYRSA_REQ_CITY
read -p "Enter EASYRSA_REQ_ORG var: " EASYRSA_REQ_ORG
read -p "Enter EASYRSA_REQ_EMAIL var: " EASYRSA_REQ_EMAIL
read -p "Enter EASYRSA_REQ_OU var: " EASYRSA_REQ_OU
#create vars for build CA. 1 var - 1 word
cat >> /opt/easy-rsa/vars <<EOF
set_var EASYRSA_REQ_COUNTRY $EASYRSA_REQ_COUNTRY
set_var EASYRSA_REQ_PROVINCE $EASYRSA_REQ_PROVINCE
set_var EASYRSA_REQ_CITY $EASYRSA_REQ_CITY
set_var EASYRSA_REQ_ORG $EASYRSA_REQ_ORG
set_var EASYRSA_REQ_EMAIL $EASYRSA_REQ_EMAIL
set_var EASYRSA_REQ_OU $EASYRSA_REQ_OU
set_var EASYRSA_ALGO "ec"
set_var EASYRSA_DIGEST "sha512"
EOF
./easyrsa build-ca
#enter the password
#enter the CN of CA ( pki.rma-dev.ru)
#CA creation complete. Your new CA certificate is at:* /opt/easy-rsa/pki/ca.crt
#FW rules. Only ICMP ping and ssh port is opened
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
sudo iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -P INPUT DROP
sudo netfilter-persistent save
sudo systemctl restart sshd

#sign openvpn server.req 
cd /opt/easy-rsa
./easyrsa sign-req server server 
#yes and passwd for pki cert
#Certificate created at: * /opt/easy-rsa/pki/issued/server.crt
#copy pki cert and signed server.crt to VPN server
scp /opt/easy-rsa/pki/ca.crt /opt/easy-rsa/pki/issued/server.crt $VPNSERVER:/opt/openvpn/certs/


#sign clients reqs
cd /opt/easy-rsa
./easyrsa sign-req client windows
#Certificate created at: * /opt/easy-rsa/pki/issued/windows.crt
scp /opt/easy-rsa/pki/issued/windows.crt $VPNSERVER:/opt/easy-rsa/pki/issued/windows.crt