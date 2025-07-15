#!/bin/bash
set -e  # Exit on error

# ====== PREREQUISITE CHECKS ======
REQUIRED_PKGS=(python3 ansible sshpass openssl)
MISSING=()
for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! command -v $pkg >/dev/null 2>&1; then
    MISSING+=("$pkg")
  fi
done
if [ ${#MISSING[@]} -ne 0 ]; then
  echo "\n[ERROR] The following required packages are missing: ${MISSING[*]}"
  echo "Install them with:"
  echo "  sudo apt update && sudo apt install -y ${MISSING[*]}"
  exit 1
fi

echo "[OK] All prerequisites are installed."

# ====== SSH KEY CHECK ======
if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
  echo "\n[INFO] No SSH key found in ~/.ssh."
  read -p "Generate a new SSH key pair for Ansible control node? [Y/n]: " genkey
  genkey=${genkey:-Y}
  if [[ $genkey =~ ^[Yy]$ ]]; then
    ssh-keygen -t ed25519 -C "ansible-control-node"
    echo "[OK] SSH key generated."
  else
    echo "[WARN] SSH key is recommended for passwordless automation."
  fi
fi

# ====== VAULT SETUP ======
echo "\n[STEP] Initializing Ansible Vault..."
if [ ! -f vault/.vault_pass ]; then
  echo "edr-secret-$(date +%s)" > vault/.vault_pass
  chmod 600 vault/.vault_pass
  echo "[OK] Vault password created at vault/.vault_pass."
else
  echo "[OK] Vault password file already exists."
fi

echo
read -p "Enter target Ubuntu server IP [127.0.0.1]: " TARGET_IP
TARGET_IP=${TARGET_IP:-127.0.0.1}

if [[ "$TARGET_IP" == "127.0.0.1" || "$TARGET_IP" == "localhost" ]]; then
  echo "[INFO] Local deployment detected. SSH key and password prompts will be skipped."
  SSH_USER=$(whoami)
  SSH_PASS=""
  ANSIBLE_CONNECTION="ansible_connection: local"
else
  read -p "Enter SSH username [ubuntu]: " SSH_USER
  SSH_USER=${SSH_USER:-ubuntu}
  read -s -p "Enter SSH password: " SSH_PASS
  echo
  # Offer to copy SSH key to backend server
  if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    read -p "Copy SSH public key to backend server for passwordless access? [Y/n]: " copypub
    copypub=${copypub:-Y}
    if [[ $copypub =~ ^[Yy]$ ]]; then
      sshpass -p "$SSH_PASS" ssh-copy-id -o StrictHostKeyChecking=no -i "$HOME/.ssh/id_ed25519.pub" "$SSH_USER@$TARGET_IP" || true
      echo "[OK] SSH key copied."
    fi
  fi
  ANSIBLE_CONNECTION=""
fi

# Create inventory
echo "[STEP] Writing inventory/hosts.yml..."
cat > inventory/hosts.yml <<EOF
all:
  children:
    edr_backend:
      hosts:
        edr_server:
          ansible_host: "$TARGET_IP"
          ansible_user: "$SSH_USER"
$(if [ -n "$ANSIBLE_CONNECTION" ]; then echo "          $ANSIBLE_CONNECTION"; fi)
EOF

# Create group variables (overwrite with defaults, user can edit before running if desired)
echo "[STEP] Writing group_vars/edr_backend.yml..."
cat > group_vars/edr_backend.yml <<'EOF'
---
# Elasticsearch
es_cluster_name: "edr-production"
es_version: "8.12.0"

# Kibana
kibana_version: "8.12.0"
kibana_port: 5601

# TheHive
thehive_version: "4.1.22"
EOF
ansible-vault encrypt group_vars/edr_backend.yml --vault-password-file vault/.vault_pass

echo "[STEP] Starting deployment..."
if [[ "$TARGET_IP" == "127.0.0.1" || "$TARGET_IP" == "localhost" ]]; then
  ansible-playbook -i inventory/hosts.yml site.yml --vault-password-file vault/.vault_pass
else
  ANSIBLE_SSH_PASS="$SSH_PASS" ANSIBLE_BECOME_PASS="$SSH_PASS" \
  ansible-playbook -i inventory/hosts.yml site.yml \
    --vault-password-file vault/.vault_pass
fi

# ====== POST-DEPLOYMENT HEALTH CHECKS ======
echo "\n[STEP] Post-deployment health checks..."
function check_service() {
  local name="$1"
  local url="$2"
  local expect="$3"
  echo -n "Checking $name at $url ... "
  if curl -sk --max-time 5 "$url" | grep -q "$expect"; then
    echo "[UP]"
  else
    echo "[WARN] Not responding as expected. Check manually."
  fi
}

check_service "Kibana" "https://$TARGET_IP:5601" "Kibana"
check_service "TheHive" "https://$TARGET_IP:9000" "TheHive"
echo "(Elasticsearch is usually not HTTP-browsable, check with: curl -sk https://$TARGET_IP:9200)"

echo "\n✅ EDR Backend Successfully Deployed!"
echo "🔗 Kibana Dashboard: https://$TARGET_IP:5601"
echo "🔗 TheHive Console: https://$TARGET_IP:9000"
echo "ℹ️ Elastic credentials: Run on server: sudo cat /etc/elasticsearch/passwords"