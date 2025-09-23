#!/bin/bash
read -p "Enter name of CLIENT for sign " CLIENT
read -p "Enter PKI-SERVER IP or DNS-name " PKISERVER
read -p "Enter username for PKISERVER " PKIUSER
read -p "Enter VPN-SERVER IP or DNS-name " VPNSERVER
read -p "Enter username for VPNSERVER " VPNUSER
scp ~/clients/reqs/$CLIENT.req $PKIUSER@$PKISERVER:/opt/easy-rsa/pki/reqs/$CLIENT.req
ssh $PKIUSER@$PKISERVER -t "/opt/easy-rsa/easyrsa --pki=/opt/easy-rsa/pki sign-req client $CLIENT"
mkdir -p ~/clients/$CLIENT
scp -r $PKIUSER@$PKISERVER:/opt/easy-rsa/pki/ca.crt ~/clients/$CLIENT/
scp -r $PKIUSER@$PKISERVER:/opt/easy-rsa/pki/issued/$CLIENT.crt ~/clients/$CLIENT/
scp -r $VPNUSER@$VPNSERVER:/opt/openvpn/certs/ta.key ~/clients/$CLIENT/
cp ~/scripts/client/base.conf ~/scripts/client/ovpn.sh ~/clients/$CLIENT/ 
