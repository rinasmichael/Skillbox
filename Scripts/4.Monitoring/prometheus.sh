#!/bin/bash
sudo apt-get update
sudo apt-get install prometheus prometheus-alertmanager -y
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/grafana-enterprise/release/12.2.0/grafana-enterprise_12.2.0_17949786146_linux_amd64.deb
sudo dpkg -i grafana-enterprise_12.2.0_17949786146_linux_amd64.deb
sudo systemctl daemon-reload
sudo systemctl restart grafana-server.service
sudo systemctl enable grafana-server.service
sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT -m comment --comment grafana











OpenVPN
sudo apt-get install prometheus-node-exporter
#OpenVpn-exporter
sudo apt-get install golang -y
wget -P ~/ https://github.com/kumina/openvpn_exporter/archive/refs/tags/v0.3.0.tar.gz
В ~/openvpn_exporter-0.3.0/main.go меняем openvpnStatusPaths на 
openvpnStatusPaths = flag.String("openvpn.status_paths", "/var/log/openvpn/openvpn-status.log", "Paths at which OpenVPN places its status files.")
sudo go build ~/openvpn_exporter-0.3.0/main.go
sudo vim /etc/systemd/system/openvpn_exporter.service:
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
#end
----

sudo addgroup --system "openvpn_exporter" --quiet
sudo adduser --system --home /usr/share/openvpn_exporter --no-create-home --ingroup "openvpn_exporter" --disabled-password --shell /bin/false "openvpn_exporter"
sudo usermod -a -G openvpn_exporter root
sudo chgrp openvpn_exporter /var/log/openvpn/openvpn-status.log
sudo chmod 660 /var/log/openvpn/openvpn-status.log
sudo chown openvpn_exporter:openvpn_exporter /usr/bin/openvpn_exporter
sudo chmod 755 /usr/bin/openvpn_exporter

sudo systemctl enable openvpn_exporter.service
sudo systemctl start openvpn_exporter.service


!!! iptables ...
sudo iptables -A INPUT -p tcp -s SOURCEIP --dport 9176 -j ACCEPT -m comment --comment prometheus_openvpn_exporter!!!!!
sudo iptables -A OUTPUT -p tcp -d DESTIP  --dport 9100 -j ACCEPT -m comment --comment Prometheus_node_exporter
sudo iptables -A OUTPUT -p tcp -d DESTIP  --dport 9176 -j ACCEPT -m comment --comment prometheus_openvpn_exporter
sudo iptables -A OUTPUT -p tcp -d DESTIP  --dport 9113 -j ACCEPT -m comment --comment prometheus_nginx_exporter

.
9176 -OpenVpn-exporter
9100 - node exporter
9090 - web prometheus
AND ENABLE TLS in all exporters....


В Prometheus config:
  - job_name: 'openvpn'
    scrape_interval: 5s
    scrape_timeout: 5s
    static_configs:
      - targets: ['vpn.rma-dev.ru:9176']
