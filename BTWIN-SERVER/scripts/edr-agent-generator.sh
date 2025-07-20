#!/bin/bash

# EDR Agent Generator
# Generates unique onboarding URLs for endpoints

set -e

# Configuration
BTWIN_SERVER_URL="${1:-http://localhost:8080}"
ENDPOINT_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== EDR Agent Generator ===${NC}"
echo -e "${GREEN}Generating onboarding URL for endpoint...${NC}"

# Create endpoint-specific configuration
ENDPOINT_CONFIG_DIR="/srv/btwin-server/endpoints/${ENDPOINT_ID}"

# Ensure the endpoints directory exists with proper permissions
sudo mkdir -p /srv/btwin-server/endpoints
sudo chown www-data:www-data /srv/btwin-server/endpoints
sudo chmod 755 /srv/btwin-server/endpoints

# Create the specific endpoint directory
sudo mkdir -p "${ENDPOINT_CONFIG_DIR}"
sudo chown www-data:www-data "${ENDPOINT_CONFIG_DIR}"
sudo chmod 755 "${ENDPOINT_CONFIG_DIR}"

# Generate Linux onboarding script
sudo tee "${ENDPOINT_CONFIG_DIR}/linux-onboard.sh" > /dev/null << 'EOF'
#!/bin/bash

# EDR Agent Linux Onboarding Script
# Generated for endpoint: ENDPOINT_ID_PLACEHOLDER

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== EDR Agent Linux Onboarding ===${NC}"

# Configuration
BTWIN_SERVER_URL="BTWIN_URL_PLACEHOLDER"
ENDPOINT_ID="ENDPOINT_ID_PLACEHOLDER"
ELASTICSEARCH_URL="ELASTICSEARCH_URL_PLACEHOLDER"

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    OS=$(uname -s)
    VER=$(uname -r)
fi

echo -e "${GREEN}Detected OS: ${OS} ${VER}${NC}"

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"

if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y curl wget unzip
elif command -v yum &> /dev/null; then
    sudo yum install -y curl wget unzip
elif command -v dnf &> /dev/null; then
    sudo dnf install -y curl wget unzip
else
    echo -e "${RED}Unsupported package manager${NC}"
    exit 1
fi

# Download and install Filebeat
echo -e "${YELLOW}Installing Filebeat...${NC}"
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.0-amd64.deb
sudo dpkg -i filebeat-8.11.0-amd64.deb

# Download Filebeat configuration
echo -e "${YELLOW}Configuring Filebeat...${NC}"
curl -o /etc/filebeat/filebeat.yml "${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/filebeat-linux.yml"

# Download and install OpenEDR
echo -e "${YELLOW}Installing OpenEDR...${NC}"
mkdir -p /opt/openedr
curl -L -o /opt/openedr/openedr-agent.tar.gz "${BTWIN_SERVER_URL}/agents/openedr-linux.tar.gz"
cd /opt/openedr
tar -xzf openedr-agent.tar.gz

# Configure OpenEDR
echo -e "${YELLOW}Configuring OpenEDR...${NC}"
curl -o /opt/openedr/config.yml "${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/openedr-config.yml"

# Install Logstash
echo -e "${YELLOW}Installing Logstash...${NC}"
curl -L -O https://artifacts.elastic.co/downloads/logstash/logstash-8.11.0-amd64.deb
sudo dpkg -i logstash-8.11.0-amd64.deb

# Configure Logstash
echo -e "${YELLOW}Configuring Logstash...${NC}"
curl -o /etc/logstash/logstash.yml "${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/logstash.yml"
curl -o /etc/logstash/conf.d/pipeline.conf "${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/logstash-pipeline.conf"

# Start services
echo -e "${YELLOW}Starting services...${NC}"
sudo systemctl enable filebeat logstash
sudo systemctl start filebeat logstash

# Start OpenEDR
echo -e "${YELLOW}Starting OpenEDR...${NC}"
cd /opt/openedr
sudo ./openedr-agent --config config.yml &

echo -e "${GREEN}=== EDR Agent installation complete! ===${NC}"
echo -e "${GREEN}Endpoint ID: ${ENDPOINT_ID}${NC}"
echo -e "${GREEN}Telemetry will be sent to: ${ELASTICSEARCH_URL}${NC}"
EOF

# Generate Windows onboarding script
sudo tee "${ENDPOINT_CONFIG_DIR}/windows-onboard.ps1" > /dev/null << 'EOF'
# EDR Agent Windows Onboarding Script
# Generated for endpoint: ENDPOINT_ID_PLACEHOLDER

param(
    [string]$BTWIN_SERVER_URL = "BTWIN_URL_PLACEHOLDER",
    [string]$ENDPOINT_ID = "ENDPOINT_ID_PLACEHOLDER",
    [string]$ELASTICSEARCH_URL = "ELASTICSEARCH_URL_PLACEHOLDER"
)

Write-Host "=== EDR Agent Windows Onboarding ===" -ForegroundColor Blue

# Create directories
$EDR_DIR = "C:\Program Files\EDR"
New-Item -ItemType Directory -Force -Path $EDR_DIR
New-Item -ItemType Directory -Force -Path "$EDR_DIR\Filebeat"
New-Item -ItemType Directory -Force -Path "$EDR_DIR\OpenEDR"
New-Item -ItemType Directory -Force -Path "$EDR_DIR\Logstash"

Write-Host "Installing Filebeat..." -ForegroundColor Yellow

# Download and install Filebeat
$filebeatUrl = "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.0-windows-x86_64.zip"
$filebeatZip = "$env:TEMP\filebeat.zip"
Invoke-WebRequest -Uri $filebeatUrl -OutFile $filebeatZip
Expand-Archive -Path $filebeatZip -DestinationPath "$EDR_DIR\Filebeat" -Force

# Download Filebeat configuration
$filebeatConfig = "$EDR_DIR\Filebeat\filebeat.yml"
Invoke-WebRequest -Uri "$BTWIN_SERVER_URL/endpoints/$ENDPOINT_ID/filebeat-windows.yml" -OutFile $filebeatConfig

Write-Host "Installing OpenEDR..." -ForegroundColor Yellow

# Download and install OpenEDR
$openedrUrl = "$BTWIN_SERVER_URL/agents/openedr-windows.zip"
$openedrZip = "$env:TEMP\openedr.zip"
Invoke-WebRequest -Uri $openedrUrl -OutFile $openedrZip
Expand-Archive -Path $openedrZip -DestinationPath "$EDR_DIR\OpenEDR" -Force

# Download OpenEDR configuration
$openedrConfig = "$EDR_DIR\OpenEDR\config.yml"
Invoke-WebRequest -Uri "$BTWIN_SERVER_URL/endpoints/$ENDPOINT_ID/openedr-config.yml" -OutFile $openedrConfig

Write-Host "Installing Logstash..." -ForegroundColor Yellow

# Download and install Logstash
$logstashUrl = "https://artifacts.elastic.co/downloads/logstash/logstash-8.11.0-windows-x86_64.zip"
$logstashZip = "$env:TEMP\logstash.zip"
Invoke-WebRequest -Uri $logstashUrl -OutFile $logstashZip
Expand-Archive -Path $logstashZip -DestinationPath "$EDR_DIR\Logstash" -Force

# Download Logstash configuration
$logstashConfig = "$EDR_DIR\Logstash\config\logstash.yml"
$logstashPipeline = "$EDR_DIR\Logstash\config\pipelines.yml"
Invoke-WebRequest -Uri "$BTWIN_SERVER_URL/endpoints/$ENDPOINT_ID/logstash.yml" -OutFile $logstashConfig
Invoke-WebRequest -Uri "$BTWIN_SERVER_URL/endpoints/$ENDPOINT_ID/logstash-pipeline.conf" -OutFile $logstashPipeline

Write-Host "Starting services..." -ForegroundColor Yellow

# Start Filebeat as Windows service
$filebeatService = "Filebeat-EDR"
$filebeatExe = "$EDR_DIR\Filebeat\filebeat.exe"
& $filebeatExe install service $filebeatService
Start-Service $filebeatService

# Start Logstash as Windows service
$logstashService = "Logstash-EDR"
$logstashExe = "$EDR_DIR\Logstash\bin\logstash.bat"
& $logstashExe install service $logstashService
Start-Service $logstashService

# Start OpenEDR
$openedrExe = "$EDR_DIR\OpenEDR\openedr-agent.exe"
Start-Process -FilePath $openedrExe -ArgumentList "--config", $openedrConfig -WindowStyle Hidden

Write-Host "=== EDR Agent installation complete! ===" -ForegroundColor Green
Write-Host "Endpoint ID: $ENDPOINT_ID" -ForegroundColor Green
Write-Host "Telemetry will be sent to: $ELASTICSEARCH_URL" -ForegroundColor Green
EOF

# Generate endpoint-specific configurations
echo -e "${YELLOW}Generating endpoint-specific configurations...${NC}"

# Filebeat Linux config
sudo tee "${ENDPOINT_CONFIG_DIR}/filebeat-linux.yml" > /dev/null << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/auth.log
    - /var/log/syslog
  fields:
    endpoint_id: ${ENDPOINT_ID}
    environment: production
    os: linux

- type: system
  enabled: true
  fields:
    endpoint_id: ${ENDPOINT_ID}
    environment: production
    os: linux

output.logstash:
  hosts: ["localhost:5044"]

logging.level: info
EOF

# Filebeat Windows config
sudo tee "${ENDPOINT_CONFIG_DIR}/filebeat-windows.yml" > /dev/null << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - C:\\Windows\\System32\\winevt\\Logs\\*.evtx
  fields:
    endpoint_id: ${ENDPOINT_ID}
    environment: production
    os: windows

- type: system
  enabled: true
  fields:
    endpoint_id: ${ENDPOINT_ID}
    environment: production
    os: windows

output.logstash:
  hosts: ["localhost:5044"]

logging.level: info
EOF

# OpenEDR config
sudo tee "${ENDPOINT_CONFIG_DIR}/openedr-config.yml" > /dev/null << EOF
endpoint:
  id: ${ENDPOINT_ID}
  name: "endpoint-${ENDPOINT_ID}"
  environment: production

telemetry:
  enabled: true
  endpoint: ${BTWIN_SERVER_URL}/telemetry
  interval: 30s

monitoring:
  processes: true
  network: true
  file_system: true
  registry: true

logging:
  level: info
  file: /var/log/openedr/agent.log
EOF

# Logstash config
sudo tee "${ENDPOINT_CONFIG_DIR}/logstash.yml" > /dev/null << EOF
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: ["${BTWIN_SERVER_URL}:9200"]
EOF

# Logstash pipeline
sudo tee "${ENDPOINT_CONFIG_DIR}/logstash-pipeline.conf" > /dev/null << EOF
input {
  beats {
    port => 5044
  }
}

filter {
  if [fields][os] == "linux" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:timestamp} %{SYSLOGFACILITY} %{DATA:program}(?:\[%{POSINT:pid}\])?: %{GREEDYDATA:log_message}" }
    }
  }
  
  mutate {
    add_field => { "endpoint_id" => "%{[fields][endpoint_id]}" }
    add_field => { "environment" => "%{[fields][environment]}" }
    add_field => { "os" => "%{[fields][os]}" }
  }
}

output {
  elasticsearch {
    hosts => ["${BTWIN_SERVER_URL}:9200"]
    index => "edr-telemetry-%{+YYYY.MM.dd}"
  }
}
EOF

# Set permissions
sudo chown -R www-data:www-data "${ENDPOINT_CONFIG_DIR}"
sudo chmod -R 755 "${ENDPOINT_CONFIG_DIR}"
sudo chmod +x "${ENDPOINT_CONFIG_DIR}/linux-onboard.sh"

# Generate onboarding URLs
LINUX_URL="${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/linux-onboard.sh"
WINDOWS_URL="${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/windows-onboard.ps1"

echo -e "${GREEN}=== EDR Agent Generated Successfully ===${NC}"
echo -e "${BLUE}Endpoint ID: ${ENDPOINT_ID}${NC}"
echo -e "${BLUE}Generated at: ${TIMESTAMP}${NC}"
echo ""
echo -e "${YELLOW}=== Onboarding URLs ===${NC}"
echo -e "${GREEN}Linux:${NC}"
echo "curl -sSL ${LINUX_URL} | bash"
echo ""
echo -e "${GREEN}Windows (PowerShell):${NC}"
echo "powershell -ExecutionPolicy Bypass -Command \"Invoke-Expression (Invoke-WebRequest -Uri '${WINDOWS_URL}' -UseBasicParsing).Content\""
echo ""
echo -e "${YELLOW}=== Direct Download URLs ===${NC}"
echo -e "${GREEN}Linux Script:${NC} ${LINUX_URL}"
echo -e "${GREEN}Windows Script:${NC} ${WINDOWS_URL}"
echo ""
echo -e "${BLUE}=== Configuration Files ===${NC}"
echo -e "${GREEN}Filebeat Linux:${NC} ${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/filebeat-linux.yml"
echo -e "${GREEN}Filebeat Windows:${NC} ${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/filebeat-windows.yml"
echo -e "${GREEN}OpenEDR Config:${NC} ${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/openedr-config.yml"
echo -e "${GREEN}Logstash Config:${NC} ${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/logstash.yml"
echo -e "${GREEN}Logstash Pipeline:${NC} ${BTWIN_SERVER_URL}/endpoints/${ENDPOINT_ID}/logstash-pipeline.conf" 