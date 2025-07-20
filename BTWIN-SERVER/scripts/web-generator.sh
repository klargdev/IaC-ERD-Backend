#!/bin/bash

# Web Generator Script for EDR Agents
# This script generates EDR agents and returns JSON response

# Set content type for JSON
echo "Content-Type: application/json"
echo ""

# Function to generate JSON response
generate_json_response() {
    local endpoint_id="$1"
    local btwin_url="$2"
    local timestamp="$3"
    
    cat << EOF
{
    "success": true,
    "endpoint_id": "$endpoint_id",
    "timestamp": "$timestamp",
    "commands": {
        "linux": "curl -sSL $btwin_url/endpoints/$endpoint_id/linux-onboard.sh | bash",
        "windows": "powershell -ExecutionPolicy Bypass -Command \"(Invoke-WebRequest -Uri '$btwin_url/endpoints/$endpoint_id/windows-onboard.ps1' -UseBasicParsing).Content | Invoke-Expression\""
    },
    "urls": {
        "linux_script": "$btwin_url/endpoints/$endpoint_id/linux-onboard.sh",
        "windows_script": "$btwin_url/endpoints/$endpoint_id/windows-onboard.ps1"
    }
}
EOF
}

# Function to generate error JSON
generate_error_json() {
    local error_message="$1"
    cat << EOF
{
    "success": false,
    "error": "$error_message"
}
EOF
}

# Get parameters from query string or POST data
BTWIN_URL="${1:-http://localhost:8080}"
ELASTICSEARCH_URL="${2:-http://localhost:9200}"

# Generate the endpoint
cd /srv/btwin-server/scripts

# Run the agent generator and capture output
OUTPUT=$(sudo ./edr-agent-generator.sh "$BTWIN_URL" 2>&1)

# Check if generation was successful
if [ $? -eq 0 ]; then
    # Extract endpoint ID from output
    ENDPOINT_ID=$(echo "$OUTPUT" | grep "Endpoint ID:" | sed 's/.*Endpoint ID: \([a-f0-9-]*\).*/\1/')
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    
    if [ -n "$ENDPOINT_ID" ]; then
        generate_json_response "$ENDPOINT_ID" "$BTWIN_URL" "$TIMESTAMP"
    else
        generate_error_json "Failed to extract endpoint ID from output"
    fi
else
    generate_error_json "Agent generation failed: $OUTPUT"
fi 