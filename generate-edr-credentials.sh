#!/bin/bash
set -e

# Default credentials (can be customized)
ELASTIC_USER="elastic"
KIBANA_USER="kibana_system"
ELASTIC_PASS="ChangeMe-EDR-$(date +%Y%m%d%H%M%S)"
KIBANA_PASS="ChangeMe-Kibana-$(date +%Y%m%d%H%M%S)"
CRED_FILE="/etc/elasticsearch/edr-credentials.txt"

# Function to reset elastic user password
reset_elastic_password() {
  echo "[INFO] Resetting $ELASTIC_USER password..."
  /usr/share/elasticsearch/bin/elasticsearch-reset-password -u $ELASTIC_USER -b -i --force <<EOF
$ELASTIC_PASS
EOF
}

# Function to create or update kibana_system user
reset_kibana_user() {
  echo "[INFO] Setting $KIBANA_USER user password via Elasticsearch API..."
  curl -sk -u $ELASTIC_USER:$ELASTIC_PASS -X POST "https://localhost:9200/_security/user/$KIBANA_USER" \
    -H 'Content-Type: application/json' \
    -d '{"password": "'$KIBANA_PASS'","roles": ["kibana_system"], "full_name": "Kibana System User"}'
}

# Save credentials to a file
save_credentials() {
  sudo bash -c "cat > $CRED_FILE" <<EOF
Elasticsearch URL: https://localhost:9200
Kibana URL:        https://localhost:5601
TheHive URL:       https://localhost:9000

Elasticsearch Username: $ELASTIC_USER
Elasticsearch Password: $ELASTIC_PASS
Kibana Username:        $KIBANA_USER
Kibana Password:        $KIBANA_PASS
EOF
  sudo chmod 600 $CRED_FILE
  echo "[INFO] Credentials saved to $CRED_FILE"
}

# Print final instructions
print_final_message() {
  echo "\n✅ EDR Backend Credentials Generated!"
  echo ""
  echo "🔗 Elasticsearch: https://localhost:9200"
  echo "🔗 Kibana Dashboard: https://localhost:5601"
  echo "🔗 TheHive Console: https://localhost:9000"
  echo ""
  echo "ℹ️  Your credentials are saved in $CRED_FILE"
  echo "   Use the above usernames and passwords to log in."
  echo "   If you forget your password, just re-run this script."
  echo ""
  echo "For more help, see the README or contact your administrator."
}

# Main
reset_elastic_password
reset_kibana_user
save_credentials
print_final_message

exit 0

# END OF SCRIPT

# Usage:
#   sudo ./generate-edr-credentials.sh
#
# This script resets/generates credentials for elastic and kibana_system users,
# saves them to /etc/elasticsearch/edr-credentials.txt, and prints service URLs.
# Run as root or with sudo. 