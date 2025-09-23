#!/bin/bash
CLIENT_FILES=.
OUTPUT_DIR=~/ovpn
BASE_CONFIG=base.conf

read -p "Please enter a VPN-CLIENT name(e-mail) " CLIENT
read -p "Please enter a VPN-SERVER IP or DNS name " VPNSERVER

cp ~/pki/private/$CLIENT.key .

if [ ! -d ${OUTPUT_DIR} ]; then
  mkdir ${OUTPUT_DIR}
fi


if [ ! -f ${BASE_CONFIG} ]; then
  echo "Error: file $BASE_CONFIG not exist!"
  exit 0
fi

if [ ! -f ${CLIENT_FILES}/${CLIENT}.crt ]; then
  echo "Error: file $CLIENT_FILES/$CLIENT.crt not exist!"
  exit 0
fi

if [ ! -f ${CLIENT_FILES}/${CLIENT}.key ]; then
  echo "Error: file $CLIENT_FILES/$CLIENT.key not exist!"
  exit 0
fi

if [ ! -f $CLIENT_FILES/ca.crt ]; then
  echo "Error: file $CLIENT_FILES/ca.crt not exist!"
  exit 0
fi

if [ ! -f $CLIENT_FILES/ta.key ]; then
  echo "Error: file $CLIENT_FILES/ta.key not exist!"
  exit 0
fi

if [ ! -d $OUTPUT_DIR ]; then
  mkdir -p $OUTPUT_DIR
  sudo chmod 700 $OUTPUT_DIR
fi


sudo sed -i "s|#VPNSERVER#|$VPNSERVER|g" ${BASE_CONFIG}
cat ${BASE_CONFIG} \
<(echo -e '<ca>') \
${CLIENT_FILES}/ca.crt \
<(echo -e '</ca>\n<cert>') \
${CLIENT_FILES}/${CLIENT}.crt \
<(echo -e '</cert>\n<key>') \
${CLIENT_FILES}/${CLIENT}.key \
<(echo -e '</key>\n<tls-crypt>') \
${CLIENT_FILES}/ta.key \
<(echo -e '</tls-crypt>') \
> ${OUTPUT_DIR}/${CLIENT}.ovpn 

if [ -f ${OUTPUT_DIR}/${CLIENT}.ovpn ]; then
  echo
  echo "Config created at: $OUTPUT_DIR/$CLIENT.ovpn "
  sudo cp $OUTPUT_DIR/$CLIENT.ovpn /etc/openvpn/$CLIENT.conf
  sudo systemctl enable openvpn@$CLIENT
else
  echo
  echo "Error: fail config created!"
  exit 1
fi
