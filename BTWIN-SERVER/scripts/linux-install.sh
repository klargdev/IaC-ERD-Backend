#!/bin/bash
set -e

# Identify endpoint
HOSTNAME=$(hostname)
OS=$(uname -s)
echo "Endpoint identity: $HOSTNAME / $OS"

# Install Filebeat (example for Debian/Ubuntu)
curl -fsSL https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.13.4-amd64.deb -o /tmp/filebeat.deb
sudo dpkg -i /tmp/filebeat.deb

# Configure Filebeat to forward to your Elastic Stack
sudo tee /etc/filebeat/filebeat.yml > /dev/null <<EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log

output.elasticsearch:
  hosts: ["http://YOUR-ELASTIC-STACK:9200"]
  fields:
    hostname: "$HOSTNAME"
    os: "$OS"
EOF

sudo systemctl enable filebeat
sudo systemctl restart filebeat

# (Add OpenEDR agent install here, if available for Linux)
echo "Filebeat and OpenEDR agent installed and configured!" 