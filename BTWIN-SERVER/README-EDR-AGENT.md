# EDR Agent System

The EDR Agent System provides automated endpoint onboarding with Filebeat and OpenEDR agents, shipping telemetry through Logstash to your Elasticsearch stack.

## Overview

The EDR Agent System consists of:

1. **Agent Generator** - Creates unique onboarding URLs for each endpoint
2. **Onboarding Scripts** - Automatically install and configure agents
3. **Telemetry Pipeline** - Filebeat → Logstash → Elasticsearch → Kibana
4. **Web Interface** - User-friendly dashboard for generating agents

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Endpoint      │    │  BTWIN-SERVER   │    │  EDR Stack      │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Filebeat    │◄┼────┼►│ Web Server  │ │    │ │ Elasticsearch│ │
│ │ OpenEDR     │ │    │ │ (Nginx)     │ │    │ │ Kibana       │ │
│ │ Logstash    │ │    │ └─────────────┘ │    │ │ TheHive      │ │
│ └─────────────┘ │    │                 │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Quick Start

### 1. Deploy the Infrastructure
```bash
# Deploy the complete EDR stack and BTWIN-SERVER
ansible-playbook -i inventory/hosts site.yml --ask-become-pass
```

### 2. Access the Web Interface
```bash
# Open in browser
http://localhost:8080
```

### 3. Generate an EDR Agent
1. Enter your BTWIN-SERVER URL (e.g., `http://localhost:8080`)
2. Enter your Elasticsearch URL (e.g., `http://localhost:9200`)
3. Click "Generate EDR Agent"
4. Copy the generated commands

### 4. Onboard an Endpoint

**Linux Endpoint:**
```bash
curl -sSL http://localhost:8080/endpoints/ENDPOINT_ID/linux-onboard.sh | bash
```

**Windows Endpoint (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-WebRequest -Uri 'http://localhost:8080/endpoints/ENDPOINT_ID/windows-onboard.ps1' -UseBasicParsing).Content"
```

## Components

### 1. Agent Generator (`edr-agent-generator.sh`)
- Creates unique endpoint IDs
- Generates endpoint-specific configurations
- Creates onboarding scripts for Linux and Windows
- Outputs ready-to-use commands

### 2. Onboarding Scripts
**Linux (`linux-onboard.sh`):**
- Installs Filebeat, OpenEDR, and Logstash
- Downloads endpoint-specific configurations
- Configures telemetry pipeline
- Starts all services

**Windows (`windows-onboard.ps1`):**
- Installs Filebeat, OpenEDR, and Logstash
- Downloads endpoint-specific configurations
- Creates Windows services
- Starts all services

### 3. Agent Configurations
**Filebeat Configs:**
- `filebeat-linux.yml` - Linux endpoint configuration
- `filebeat-windows.yml` - Windows endpoint configuration
- Includes endpoint ID and environment tags

**OpenEDR Configs:**
- `openedr-config.yml` - Agent configuration
- Includes endpoint ID and telemetry settings

**Logstash Configs:**
- `logstash.yml` - Logstash server configuration
- `logstash-pipeline.conf` - Data processing pipeline

### 4. Web Interface (`index.html`)
- Modern, responsive web dashboard
- Form-based agent generation
- Displays onboarding commands
- Links to all available services

## Directory Structure

```
/srv/btwin-server/
├── index.html                    # Web interface
├── nginx-btwin-server.conf.j2    # Nginx configuration
├── configs/                      # Filebeat configurations
│   ├── filebeat-linux.yml
│   └── filebeat-windows.yml
├── bootstrap/                    # Basic bootstrap scripts
│   ├── linux-bootstrap.sh
│   └── windows-bootstrap.ps1
├── scripts/                      # EDR agent scripts
│   ├── edr-agent-generator.sh
│   └── setup-edr-agents.sh
├── agents/                       # Agent binaries
│   ├── openedr-linux.tar.gz
│   ├── openedr-windows.zip
│   └── download-agents.sh
└── endpoints/                    # Generated endpoint configs
    └── {endpoint-id}/
        ├── linux-onboard.sh
        ├── windows-onboard.ps1
        ├── filebeat-linux.yml
        ├── filebeat-windows.yml
        ├── openedr-config.yml
        ├── logstash.yml
        └── logstash-pipeline.conf
```

## Usage Examples

### Generate an Agent from Command Line
```bash
# Run the agent generator
sudo /srv/btwin-server/scripts/edr-agent-generator.sh http://localhost:8080

# Output will include:
# - Endpoint ID
# - Linux onboarding command
# - Windows onboarding command
# - Direct download URLs
```

### Onboard Multiple Endpoints
```bash
# Generate agent for endpoint 1
sudo /srv/btwin-server/scripts/edr-agent-generator.sh http://localhost:8080

# Generate agent for endpoint 2
sudo /srv/btwin-server/scripts/edr-agent-generator.sh http://localhost:8080

# Each gets a unique endpoint ID and configuration
```

### Monitor Endpoints in Kibana
1. Open Kibana: `http://localhost:5601`
2. Go to Discover
3. Search for your endpoint ID
4. View telemetry data

## Configuration

### Customizing Agent Configurations
Edit the templates in `edr-agent-generator.sh`:

```bash
# Filebeat configuration
cat > "${ENDPOINT_CONFIG_DIR}/filebeat-linux.yml" << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
  fields:
    endpoint_id: ${ENDPOINT_ID}
    environment: production
    os: linux
EOF
```

### Adding Custom Log Sources
```bash
# Add custom log paths to Filebeat config
paths:
  - /var/log/*.log
  - /var/log/auth.log
  - /var/log/syslog
  - /custom/application/*.log  # Add your custom logs
```

### Customizing OpenEDR Configuration
```bash
# Edit OpenEDR config template
cat > "${ENDPOINT_CONFIG_DIR}/openedr-config.yml" << EOF
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
EOF
```

## Troubleshooting

### Common Issues

**1. Agent Installation Fails**
```bash
# Check if services are running
sudo systemctl status filebeat logstash

# Check logs
sudo journalctl -u filebeat -f
sudo journalctl -u logstash -f
```

**2. Telemetry Not Reaching Elasticsearch**
```bash
# Check Logstash pipeline
sudo /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/pipeline.conf --config.test_and_exit

# Check Elasticsearch connectivity
curl http://localhost:9200/_cluster/health
```

**3. Web Interface Not Accessible**
```bash
# Check Nginx status
sudo systemctl status nginx

# Check Nginx configuration
sudo nginx -t

# Check logs
sudo tail -f /var/log/nginx/btwin-server_error.log
```

**4. Endpoint Configurations Not Found**
```bash
# Check if endpoint directory exists
ls -la /srv/btwin-server/endpoints/

# Check permissions
sudo chown -R www-data:www-data /srv/btwin-server/endpoints/
sudo chmod -R 755 /srv/btwin-server/endpoints/
```

### Debugging Commands

**Check Endpoint Status:**
```bash
# List all endpoints
ls -la /srv/btwin-server/endpoints/

# Check specific endpoint
ls -la /srv/btwin-server/endpoints/{endpoint-id}/
```

**Test Configuration Downloads:**
```bash
# Test Linux config download
curl http://localhost:8080/endpoints/{endpoint-id}/filebeat-linux.yml

# Test Windows config download
curl http://localhost:8080/endpoints/{endpoint-id}/filebeat-windows.yml
```

**Monitor Telemetry:**
```bash
# Check Elasticsearch indices
curl http://localhost:9200/_cat/indices/edr-telemetry*

# Check Logstash pipeline
curl http://localhost:9600/_node/stats/pipeline
```

## Security Considerations

### 1. Network Security
- Use HTTPS for production deployments
- Implement proper firewall rules
- Consider VPN for remote endpoints

### 2. Agent Security
- Use unique endpoint IDs
- Implement agent authentication
- Encrypt sensitive configurations

### 3. Data Security
- Encrypt telemetry data in transit
- Implement proper access controls
- Regular security updates

## Production Deployment

### 1. Update Agent Binaries
Replace placeholder binaries with actual OpenEDR agents:

```bash
# Download actual OpenEDR binaries
cd /srv/btwin-server/agents/
curl -L -o openedr-linux.tar.gz "https://github.com/openedr/openedr/releases/latest/download/openedr-linux.tar.gz"
curl -L -o openedr-windows.zip "https://github.com/openedr/openedr/releases/latest/download/openedr-windows.zip"
```

### 2. Configure SSL/TLS
```bash
# Generate SSL certificates
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/btwin-server.key \
  -out /etc/ssl/certs/btwin-server.crt

# Update Nginx configuration for HTTPS
```

### 3. Implement Authentication
```bash
# Add basic authentication to Nginx
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

### 4. Monitoring and Alerting
- Set up Kibana alerts
- Monitor agent health
- Implement log retention policies

## API Reference

### Endpoints

**Generate Agent:**
```bash
GET /scripts/edr-agent-generator.sh?url={btwin_url}
```

**Download Configurations:**
```bash
GET /endpoints/{endpoint-id}/filebeat-linux.yml
GET /endpoints/{endpoint-id}/filebeat-windows.yml
GET /endpoints/{endpoint-id}/openedr-config.yml
GET /endpoints/{endpoint-id}/logstash.yml
GET /endpoints/{endpoint-id}/logstash-pipeline.conf
```

**Download Onboarding Scripts:**
```bash
GET /endpoints/{endpoint-id}/linux-onboard.sh
GET /endpoints/{endpoint-id}/windows-onboard.ps1
```

**Download Agent Binaries:**
```bash
GET /agents/openedr-linux.tar.gz
GET /agents/openedr-windows.zip
```

**Telemetry Endpoint:**
```bash
POST /telemetry/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

For more information, see the main README.md or contact the development team. 