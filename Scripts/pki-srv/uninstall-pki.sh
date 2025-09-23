#!/bin/bash
sudo apt purge easy-rsa iptables-persistent -y
sudo rm -rf /usr/share/easy-rsa/* /opt/easy-rsa/
