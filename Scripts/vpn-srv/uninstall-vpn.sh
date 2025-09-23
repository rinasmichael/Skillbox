#!/bin/bash
sudo systemctl disable openvpn
sudo systemctl stop openvpn-server@server.service 

sudo apt purge easy-rsa iptables-persistent openvpn -y
sudo rm -rf /usr/share/easy-rsa/* /opt/easy-rsa/* ~/clients/* /opt/openvpn/* /etc/openvpn/* /var/log/openvpn/*
