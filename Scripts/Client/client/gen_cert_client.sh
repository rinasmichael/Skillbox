#!/bin/bash
sudo apt-get update && sudo apt-get install easy-rsa -y
/usr/share/easy-rsa/easyrsa --pki-dir=/home/$USER/pki init-pki 
read -p "Enter name of VPN-Client(your e-mail) " VPNCLIENT
if [ -z "$VPNCLIENT" ]; then
  echo "Name is null...exiting..."
  exit 1
fi
/usr/share/easy-rsa/easyrsa --pki-dir=/home/$USER/pki --batch gen-req $VPNCLIENT nopass
cat /home/$USER/pki/reqs/$VPNCLIENT.req
read -p "Please send request cert(/home/$USER/pki/reqs/$VPNCLIENT.req) to admins"
