#!/bin/bash
if [[ "${UID}" -ne 0 ]]; then
  echo -e "You need to run this script as root!"
  exit 1
fi

while [ -z $PROMETHEUS ]; do
read -p "Please enter IP-Address or Domain Name of this PROMETHEUS server " PROMETHEUS
done
while [ -z $PKISERVER ]; do
read -p "Please enter IP-Address or Domain Name of PKI-SERVER " PKISERVER
done
while [ -z $VPNSERVER ]; do
read -p "Please enter IP-Address or Domain Name of VPNSERVER " VPNSERVER
done

while [ -z $EMAIL ]; do
read -p "Please enter your email for ALERTMANAGER notifications " EMAIL
done
while [ -z $SMTPSERVER ]; do
read -p "Please enter SMTP SERVER with port for ALERTMANGER notifications (ex. smtp.yandex.ru:587) " SMTPSERVER
done
while [ -z $AUTH_PASSWORD ]; do
read -p "Please enter PASSWORD for your email $EMAIL " AUTH_PASSWORD
done

wget https://raw.githubusercontent.com/rinasmichael/Skillbox/refs/heads/main/Scripts/4.Monitoring/rules.yml
wget https://raw.githubusercontent.com/rinasmichael/Skillbox/refs/heads/main/Scripts/4.Monitoring/prometheus.yml
sudo sed -i "s|#PROMETHEUS#|$PROMETHEUS|g" prometheus.yml
sudo sed -i "s|#PKISERVER#|$PKISERVER|g" prometheus.yml
sudo sed -i "s|#VPNSERVER#|$VPNSERVER|g" prometheus.yml

wget https://github.com/rinasmichael/Skillbox/raw/refs/heads/main/Scripts/4.Monitoring/alertmanager.yml
sudo sed -i "s|#EMAIL#|$EMAIL|g" alertmanager.yml
sudo sed -i "s|#SMTPSERVER#|$SMTPSERVER|g" alertmanager.yml
sudo sed -i "s|#AUTH_PASSWORD#|$AUTH_PASSWORD|g" alertmanager.yml

wget https://github.com/rinasmichael/Skillbox/releases/download/grafana/grafana-enterprise_12.2.0_17949786146_linux_amd64.deb
sudo debconf-set-selections <<EOF
iptables-persistent iptables-persistent/autosave_v4 boolean true
iptables-persistent iptables-persistent/autosave_v6 boolean true
EOF

sudo apt-get update
sudo apt-get install prometheus prometheus-alertmanager iptables-persistent adduser libfontconfig1 musl -y
sudo dpkg -i grafana-enterprise_12.2.0_17949786146_linux_amd64.deb
sudo mv -f prometheus.yml /etc/prometheus/prometheus.yml
sudo mv -f rules.yml /etc/prometheus/rules.yml
sudo mv -f alertmanager.yml /etc/prometheus/alertmanager.yml
sudo systemctl daemon-reload
sudo systemctl restart grafana-server.service
sudo systemctl enable grafana-server.service
sudo systemctl restart prometheus.service
sudo systemctl restart prometheus-alertmanager
sudo systemctl restart prometheus-alertmanager.service

sudo iptables -A INPUT -p tcp -m multiport --dports 22,3000,9090,9093,9100 -j ACCEPT
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
sudo netfilter-persistent save
