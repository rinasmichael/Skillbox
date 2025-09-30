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

В Prometheus config:
  - job_name: 'openvpn'
    scrape_interval: 5s
    scrape_timeout: 5s
    static_configs:
      - targets: ['vpn.rma-dev.ru:9176']
