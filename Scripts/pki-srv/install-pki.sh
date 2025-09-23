#!/bin/bash
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

sudo apt-get update && sudo apt install easy-rsa iptables-persistent -y
sudo mkdir /opt/easy-rsa
sudo ln -s /usr/share/easy-rsa/* /opt/easy-rsa/
sudo chown -R $USER:$USER /opt/easy-rsa
/opt/easy-rsa/easyrsa --pki=/opt/easy-rsa/pki --batch init-pki
sudo sed -i '/PermitRootLogin\|PermitEmptyPasswords\|PasswordAuthentication\|PubkeyAuthentication/Id' /etc/ssh/sshd_config
sudo bash -c "cat >> /etc/ssh/sshd_config <<EOF
PermitRootLogin No
PasswordAuthentication No
PermitEmptyPasswords No
PubkeyAuthentication yes
EOF
"
echo "Please enter vars for build CA. 1 var - 1 word"
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
/opt/easy-rsa/easyrsa --pki=/opt/easy-rsa/pki build-ca 
#FW rules. Only ICMP ping and ssh port is opened
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
sudo iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -P INPUT DROP
sudo netfilter-persistent save
sudo systemctl restart ssh


