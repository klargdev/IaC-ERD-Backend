# EDR Backend Stack Deployment (Ansible)

> **Note:** This stack is open by default (no authentication or passwords) and is intended for local development or testing only. **Do not use in production as-is!**

## System Design

### 3.2 SYSTEM DESIGN

This section details how we implemented an Infrastructure as Code (IaC) solution using Ansible playbooks to deploy a comprehensive EDR (Endpoint Detection and Response) backend infrastructure with SSH remote access capabilities. The system consists of a centralized deployment pipeline that automatically provisions and configures the entire security stack, followed by a remote agent onboarding system that enables seamless endpoint integration.

### **Core Infrastructure Deployment**
The Ansible playbook (`site.yml`) orchestrates the deployment of three critical components:

1. **SSH Server Configuration**: Automatically installs and configures OpenSSH server on both EDR backend and BTWIN-SERVER hosts, enabling secure remote access for system administration and monitoring.

2. **Elasticsearch Stack**: Deploys Elasticsearch with SSL certificate generation, providing the foundational data storage and search capabilities for security telemetry.

3. **Kibana**: Installs and configures Kibana with SSL certificates, enabling data visualization and analysis of security events.

4. **TheHive**: Deploys TheHive with SSL certificate configuration, providing the incident response and case management platform.

### **Remote Access and Management**
The system provides secure SSH access to all deployed components:

- **EDR Backend SSH Access**: Secure SSH connection to the main EDR server for system administration, log monitoring, and service management
- **BTWIN-SERVER SSH Access**: Remote access to the agent distribution server for configuration updates and monitoring
- **Automated SSH Configuration**: Ansible automatically configures SSH with security best practices including:
  - Strong cipher and key exchange algorithms
  - Proper authentication settings
  - Secure logging and monitoring
  - Connection timeout and keepalive settings

### **BTWIN-SERVER (Betweener) Architecture**
A custom middleware server (`BTWIN-SERVER`) serves as the central hub for endpoint onboarding and agent distribution:

- **Web Interface**: Provides a user-friendly web interface for generating unique endpoint onboarding URLs
- **API Server**: Python-based REST API (`api-server.py`) that handles agent generation requests and manages the onboarding pipeline
- **Agent Repository**: Centralized storage for EDR agent binaries, configurations, and onboarding scripts
- **Nginx Integration**: Reverse proxy configuration for secure file distribution and web interface hosting

### **Remote Installation Pipeline**
The system implements a sophisticated remote deployment pipeline through the following components:

1. **Agent Generator Script** (`edr-agent-generator.sh`): Creates unique endpoint IDs and generates platform-specific onboarding scripts (Linux/Windows)

2. **Configuration Templates**: Dynamically generates endpoint-specific configurations for:
   - Filebeat (log collection and forwarding)
   - OpenEDR (endpoint monitoring agent)
   - Logstash (data processing pipeline)

3. **Onboarding Scripts**: Platform-specific installation scripts that:
   - Download official agent binaries from Elastic and OpenEDR repositories
   - Install and configure Filebeat, Logstash, and OpenEDR agents
   - Establish secure communication channels to the Elasticsearch backend
   - Configure real-time telemetry forwarding

### **Data Flow Architecture**
The implemented data flow follows this pattern:

1. **Endpoint Monitoring**: OpenEDR agents continuously monitor endpoint activities (processes, network connections, file system changes, registry modifications)

2. **Telemetry Collection**: Filebeat collects system logs and security events, while Logstash processes and enriches the data

3. **Real-time Forwarding**: Processed security telemetry is forwarded in real-time to Elasticsearch for indexing and analysis

4. **Data Visualization**: Kibana provides interactive dashboards for security analysts to monitor and analyze endpoint activities

5. **Incident Management**: TheHive integration enables security teams to create, track, and manage security incidents based on detected threats

### **Security and Scalability Features**
- **SSH Remote Access**: Secure SSH connections for remote system administration and monitoring
- **SSL/TLS Encryption**: All components communicate over encrypted channels using self-signed certificates
- **Unique Endpoint Identification**: Each endpoint receives a unique UUID for tracking and management
- **Modular Architecture**: Components can be deployed independently or as a complete stack
- **Idempotent Deployment**: Ansible playbooks can be safely re-run without affecting existing configurations
- **Multi-platform Support**: Native support for both Linux and Windows endpoint onboarding

This architecture provides a complete, production-ready EDR backend infrastructure that enables organizations to deploy, monitor, and respond to security threats across distributed endpoint environments through a centralized, automated management system with secure remote access capabilities.

## System Requirements
- **Minimum:** 2GB RAM, 2 CPUs
- **OS:** Ubuntu (tested on 20.04/22.04)
- **Ansible:** v2.10+

## Deployment Options

### Option 1: Main System (Recommended)
Deploy directly on your main system for best performance and easiest access.

**Setup:**
```bash
# Install Ansible on your main system
sudo apt update
sudo apt install ansible

# Clone/copy the project to your main system
# Ensure inventory/hosts contains:
[edr_backend]
localhost ansible_connection=local

[btwin_server]
localhost ansible_connection=local
```

**Benefits:**
- ✅ No VM overhead
- ✅ Direct network access
- ✅ Easier port forwarding
- ✅ Better performance
- ✅ Simpler troubleshooting

### Option 2: Virtual Machine (VirtualBox/VMware)
For isolated testing environments.

**VirtualBox Setup:**
1. **Shut down VM** → **Settings** → **Network**
2. **Select "NAT"** → **Advanced** → **Port Forwarding**
3. **Add rule:**
   - **Name**: HTTP
   - **Protocol**: TCP
   - **Host Port**: 8080
   - **Guest Port**: 80
4. **Start VM and test:**
   ```bash
   # From host machine
   curl http://localhost:8080
   ```

**Alternative - Bridged Adapter:**
1. **VM Settings** → **Network** → **Bridged Adapter**
2. **Restart VM**
3. **Find VM IP:**
   ```bash
   ip addr show
   ```
4. **Test from host:**
   ```bash
   curl http://VM_IP_ADDRESS
   ```

### Option 3: Cloud Provider (AWS, DigitalOcean, etc.)
For external access and production-like environments.

**Required Setup:**
1. **Firewall Configuration:**
   - Allow port 80 (HTTP)
   - Allow port 22 (SSH)
   - Allow port 5601 (Kibana)
   - Allow port 9000 (TheHive)

2. **DNS Configuration:**
   - Point your domain's A record to your server IP
   - Update the Nginx config with your domain

## Pre-Deployment Configuration

### 1. Configure Your Domain Name
Before running the deployment, edit the Nginx configuration to add your domain name:

```bash
# Edit the Nginx configuration template
nano BTWIN-SERVER/nginx-btwin-server.conf.j2
```

Replace `your-domain.com` with your actual domain name in the server_name directive.

### 2. Verify Inventory
Ensure your inventory file (`inventory/hosts`) contains the correct host information for both EDR backend and BTWIN-SERVER deployment.

## Cleanup Broken Elasticsearch Install
If your Elasticsearch installation is broken, or you want to start fresh, run the cleanup playbook:

```bash
ansible-playbook -i inventory/hosts cleanup.yml --ask-become-pass
```

**Note:** When prompted for BECOME password, enter your **sudo password** (the same password you use when running `sudo` commands).

This will:
- Stop Elasticsearch, Kibana, and TheHive if running
- Remove all related packages, data, logs, and configuration
- Remove the Elastic GPG key and repository
- Leave your system ready for a clean redeployment

## Deployment Instructions
1. **(Optional but recommended)** Run the cleanup playbook above if you have a failed or partial install.
2. **Configure your domain name** in `BTWIN-SERVER/nginx-btwin-server.conf.j2` (see Pre-Deployment Configuration above).
3. Deploy the full EDR backend stack and BTWIN-SERVER:

```bash
ansible-playbook -i inventory/hosts site.yml --ask-become-pass
```

**Note:** When prompted for BECOME password, enter your **sudo password** (the same password you use when running `sudo` commands).

This will:
- Install Java, Elasticsearch, Kibana, and TheHive
- Create all required directories and configuration files
- Set correct permissions
- Generate and configure self-signed TLS certificates
- Start all services and verify they are running
- Deploy BTWIN-SERVER (betweener) with Nginx for endpoint onboarding
- Configure Filebeat templates for Linux and Windows endpoints
- **Install and configure the web API server** for EDR agent generation
- **Set up the systemd service** for the API server
- **Configure the web interface** to properly generate endpoints

## Accessing Services
- **Elasticsearch:** https://localhost:9200
- **Kibana:** https://localhost:5601
- **TheHive:** https://localhost:9000
- **BTWIN-SERVER:** http://localhost (or your configured domain)

## Testing Your Deployment

### 1. Test Locally
```bash
# Test main interface
curl http://localhost

# Test configs directory
curl http://localhost/configs/

# Test bootstrap scripts
curl http://localhost/bootstrap/linux-bootstrap.sh
```

### 2. Test from External Network
```bash
# Find your server's IP
curl ifconfig.me

# Test from another device
curl http://YOUR_SERVER_IP
```

### 3. Test Endpoint Onboarding

**Test the Web Interface:**
1. Open http://localhost in your browser
2. Fill in the configuration and click "Generate EDR Agent"
3. Verify that files are created in `/srv/btwin-server/endpoints/[endpoint-id]/`

**Test Command Line Generation:**
```bash
# Generate a test endpoint
sudo /srv/btwin-server/scripts/edr-agent-generator.sh http://localhost

# Check if files were created
ls -la /srv/btwin-server/endpoints/

# Test the generated scripts
curl -sSL http://localhost/endpoints/[endpoint-id]/linux-onboard.sh | head -10
```

## Endpoint Onboarding

### Web Interface (Recommended)
The BTWIN-SERVER web interface now provides a complete, production-ready EDR agent onboarding system for Windows endpoints only:

1. **Access the web interface:** http://localhost (or your configured domain)
2. **Fill in the configuration:**
   - BTWIN Server URL: `http://localhost` (or your domain)
   - Elasticsearch URL: `http://localhost:9200`
3. **Click "Generate EDR Agent"**
4. **The system will:**
   - ✅ Automatically download the latest official OpenEDR, Filebeat, and Logstash Windows agent files from their official sources (if not already present)
   - ✅ Show real-time status/progress messages for each download
   - ✅ Display the official download links for transparency
   - ✅ Only after all downloads succeed, generate onboarding scripts and present working download URLs
   - ✅ Create actual files in `/srv/btwin-server/endpoints/[endpoint-id]/`
   - ✅ Show success confirmation

**No placeholders are used—everything is real and production-ready.**

### Command Line Generation
For manual generation or scripting:

```bash
# Generate a new endpoint
sudo /srv/btwin-server/scripts/edr-agent-generator.sh http://localhost

# The generated files will be in:
# /srv/btwin-server/endpoints/[endpoint-id]/
```

### What's Generated
Each endpoint gets:
- **Windows onboarding script** (`windows-onboard.ps1`)
- **Filebeat configuration** for Windows
- **OpenEDR configuration** for Windows
- **Logstash configuration** for Windows

### Using the Generated Scripts

**Windows Endpoint (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -Command "New-Item -ItemType Directory -Force -Path 'C:\temp'; Invoke-WebRequest -Uri 'http://localhost/endpoints/[endpoint-id]/windows-onboard.ps1' -OutFile 'C:\temp\onboard.ps1'; & 'C:\temp\onboard.ps1'"
```

### Official Agent Download Links
The web interface displays the official download links for:
- OpenEDR (Windows)
- Filebeat (Windows)
- Logstash (Windows)

This ensures transparency and that you are always using the latest, official agent binaries.

## Troubleshooting

### Service Startup Issues
- **If Elasticsearch, Kibana, or TheHive fails to start:**
  - Run the cleanup playbook, then redeploy.
  - Check system requirements (RAM/CPU)
  - Review logs in `/var/log/elasticsearch/`, `/var/log/kibana/`, or `/var/log/thehive/`

### Network Access Issues

**Main System:**
```bash
# Check if services are running
sudo systemctl status nginx elasticsearch kibana thehive

# Check if ports are listening
sudo netstat -tlnp | grep -E ':(80|5601|9000|9200)'

# Test locally
curl http://localhost
```

**Virtual Machine:**
```bash
# Check port forwarding (VirtualBox)
# VM Settings → Network → Port Forwarding

# Test from host
curl http://localhost:8080  # If using port forwarding
curl http://VM_IP_ADDRESS   # If using bridged adapter
```

**Cloud Provider:**
```bash
# Check firewall rules in cloud dashboard
# Allow ports: 22, 80, 5601, 9000, 9200

# Test connectivity
curl http://YOUR_SERVER_IP

# Check if domain resolves
nslookup your-domain.com
```

### BTWIN-SERVER Issues
- **If BTWIN-SERVER is not accessible:**
  - Check Nginx status: `systemctl status nginx`
  - Verify domain configuration in `/etc/nginx/sites-available/btwin-server.conf`
  - Check Nginx logs: `tail -f /var/log/nginx/error.log`
  - Verify file permissions: `sudo chown -R www-data:www-data /srv/btwin-server/`

- **If the web interface doesn't generate endpoints:**
  - Check API server status: `systemctl status btwin-api.service`
  - Restart the API service: `sudo systemctl restart btwin-api.service`
  - Check API server logs: `journalctl -u btwin-api.service -f`
  - Verify the API is accessible: `curl -X POST http://localhost:8081/ -d "url=http://localhost&elasticsearch=http://localhost:9200"`

- **If endpoint files are not created:**
  - Check script permissions: `chmod +x /srv/btwin-server/scripts/*.sh`
  - Verify the endpoints directory exists: `ls -la /srv/btwin-server/endpoints/`
  - Test manual generation: `sudo /srv/btwin-server/scripts/edr-agent-generator.sh http://localhost`

### Common Error Solutions

**403 Forbidden:**
```bash
sudo chown -R www-data:www-data /srv/btwin-server/
sudo chmod -R 755 /srv/btwin-server/
```

**Connection Timeout:**
- Check firewall settings (UFW or cloud provider)
- Verify port forwarding (VM)
- Check if services are running

**Domain Not Resolving:**
- Verify DNS A record points to correct IP
- Check cloud provider firewall allows port 80
- Test with IP address instead of domain

### Playbook Issues
- **Playbook is idempotent:** You can safely re-run it multiple times.
- **For persistent issues:** Use the cleanup playbook to reset the environment.

## Recent Improvements (v2.0)

### ✅ Fixed Web Interface
- **Problem:** Web interface generated commands but didn't create actual files
- **Solution:** Implemented proper API server that calls the backend scripts
- **Result:** Web interface now actually creates files in `/srv/btwin-server/endpoints/`

### ✅ Fixed Script Generation
- **Problem:** Generated scripts had placeholder values like `BTWIN_URL_PLACEHOLDER`
- **Solution:** Fixed heredoc syntax and variable substitution in generator scripts
- **Result:** Generated scripts now work properly with actual URLs and endpoint IDs

### ✅ Added API Server
- **New:** Python API server running on port 8081
- **New:** Systemd service for automatic management
- **New:** Proper error handling and JSON responses

### ✅ Enhanced Web Interface
- **New:** Real-time endpoint generation
- **New:** Success/error feedback
- **New:** Working download URLs
- **New:** Automatic file creation confirmation

## External Access (Optional)

### Port Forwarding (Router)
Configure your router to forward port 80 to your main system's local IP.

### Dynamic DNS
Use services like No-IP or DuckDNS for a domain name that updates with your IP.

### Cloudflare Tunnel
For secure external access without opening ports.

---

For more help, see the comments in the playbooks or contact your administrator.

