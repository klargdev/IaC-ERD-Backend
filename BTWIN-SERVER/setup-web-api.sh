#!/bin/bash

# Setup script for BTWIN EDR Web API
echo "=== Setting up BTWIN EDR Web API ==="

# Make scripts executable
chmod +x /srv/btwin-server/scripts/*.sh
chmod +x /srv/btwin-server/api-server.py

# Create endpoints directory if it doesn't exist
sudo mkdir -p /srv/btwin-server/endpoints
sudo chown www-data:www-data /srv/btwin-server/endpoints
sudo chmod 755 /srv/btwin-server/endpoints

# Install systemd service
sudo cp /srv/btwin-server/btwin-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable btwin-api.service
sudo systemctl start btwin-api.service

# Check if service is running
if sudo systemctl is-active --quiet btwin-api.service; then
    echo "✅ API server is running"
else
    echo "❌ API server failed to start"
    sudo systemctl status btwin-api.service
fi

# Test the API
echo "Testing API endpoint..."
curl -X POST http://localhost:8081/ \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "url=http://localhost:8080&elasticsearch=http://localhost:9200" \
  --max-time 10

echo ""
echo "=== Setup Complete ==="
echo "The web interface should now properly generate endpoints in /srv/btwin-server/endpoints/" 