#!/bin/bash

# CGI Script for EDR Agent Generation
# This script handles web requests to generate EDR agents

# Set content type
echo "Content-Type: text/plain"
echo ""

# Check if this is a POST request
if [ "$REQUEST_METHOD" != "POST" ]; then
    echo "Error: Only POST requests are supported"
    exit 1
fi

# Read POST data
read -t 10 POST_DATA

# Parse the POST data
BTWIN_URL=$(echo "$POST_DATA" | sed -n 's/.*url=\([^&]*\).*/\1/p' | sed 's/%20/ /g' | sed 's/%3A/:/g' | sed 's/%2F/\//g')
ELASTICSEARCH_URL=$(echo "$POST_DATA" | sed -n 's/.*elasticsearch=\([^&]*\).*/\1/p' | sed 's/%20/ /g' | sed 's/%3A/:/g' | sed 's/%2F/\//g')

# URL decode
BTWIN_URL=$(printf '%b' "${BTWIN_URL//%/\\x}")
ELASTICSEARCH_URL=$(printf '%b' "${ELASTICSEARCH_URL//%/\\x}")

# Set defaults if not provided
BTWIN_URL=${BTWIN_URL:-"http://localhost:8080"}
ELASTICSEARCH_URL=${ELASTICSEARCH_URL:-"http://localhost:9200"}

# Run the agent generator
cd /srv/btwin-server/scripts
sudo ./edr-agent-generator.sh "$BTWIN_URL" 2>&1 