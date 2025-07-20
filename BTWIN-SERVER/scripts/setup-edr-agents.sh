#!/bin/bash

# EDR Agents Setup Script
# Creates agent binaries and directories for the EDR system

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== EDR Agents Setup ===${NC}"

# Create agents directory
AGENTS_DIR="/srv/btwin-server/agents"
sudo mkdir -p "${AGENTS_DIR}"

echo -e "${YELLOW}Creating agent binaries...${NC}"

# Create placeholder OpenEDR Linux agent
cat > "${AGENTS_DIR}/openedr-linux.tar.gz" << 'EOF'
# This is a placeholder for the OpenEDR Linux agent
# In a real deployment, this would be the actual OpenEDR binary
# For now, we'll create a simple script that simulates the agent

#!/bin/bash
echo "OpenEDR Linux Agent - Placeholder"
echo "In production, this would be the actual OpenEDR binary"
echo "Endpoint ID: $1"
echo "Config: $2"
EOF

# Create placeholder OpenEDR Windows agent
cat > "${AGENTS_DIR}/openedr-windows.zip" << 'EOF'
# This is a placeholder for the OpenEDR Windows agent
# In a real deployment, this would be the actual OpenEDR binary
# For now, we'll create a simple script that simulates the agent

@echo off
echo OpenEDR Windows Agent - Placeholder
echo In production, this would be the actual OpenEDR binary
echo Endpoint ID: %1
echo Config: %2
EOF

# Create a simple agent downloader script
cat > "${AGENTS_DIR}/download-agents.sh" << 'EOF'
#!/bin/bash

# Agent Downloader Script
# Downloads actual agent binaries from official sources

set -e

AGENTS_DIR="/srv/btwin-server/agents"
cd "${AGENTS_DIR}"

echo "Downloading EDR agent binaries..."

# Download OpenEDR Linux (placeholder - replace with actual URL)
echo "Downloading OpenEDR Linux agent..."
# curl -L -o openedr-linux.tar.gz "https://github.com/openedr/openedr/releases/latest/download/openedr-linux.tar.gz"

# Download OpenEDR Windows (placeholder - replace with actual URL)
echo "Downloading OpenEDR Windows agent..."
# curl -L -o openedr-windows.zip "https://github.com/openedr/openedr/releases/latest/download/openedr-windows.zip"

echo "Agent binaries downloaded successfully!"
echo "Note: This script contains placeholder URLs. Update with actual OpenEDR download URLs."
EOF

# Set permissions
sudo chown -R www-data:www-data "${AGENTS_DIR}"
sudo chmod -R 755 "${AGENTS_DIR}"
sudo chmod +x "${AGENTS_DIR}/download-agents.sh"

echo -e "${GREEN}=== EDR Agents Setup Complete ===${NC}"
echo -e "${BLUE}Agents directory: ${AGENTS_DIR}${NC}"
echo -e "${YELLOW}Note: Placeholder agent binaries created.${NC}"
echo -e "${YELLOW}Update with actual OpenEDR binaries for production use.${NC}" 