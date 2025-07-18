# EDR Backend Stack Deployment (Ansible)

> **Note:** This stack is open by default (no authentication or passwords) and is intended for local development or testing only. **Do not use in production as-is!**

## System Requirements
- **Minimum:** 2GB RAM, 2 CPUs
- **OS:** Ubuntu (tested on 20.04/22.04)
- **Ansible:** v2.10+

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

## Accessing Services
- **Elasticsearch:** https://localhost:9200
- **Kibana:** https://localhost:5601
- **TheHive:** https://localhost:9000
- **BTWIN-SERVER:** http://localhost (or your configured domain)

## Endpoint Onboarding
The BTWIN-SERVER provides:
- Filebeat configuration templates for Linux and Windows endpoints
- Downloadable agent configurations
- Centralized endpoint management interface

## Troubleshooting
- **If Elasticsearch, Kibana, or TheHive fails to start:**
  - Run the cleanup playbook, then redeploy.
  - Check system requirements (RAM/CPU)
  - Review logs in `/var/log/elasticsearch/`, `/var/log/kibana/`, or `/var/log/thehive/`
- **If BTWIN-SERVER is not accessible:**
  - Check Nginx status: `systemctl status nginx`
  - Verify domain configuration in `/etc/nginx/sites-available/btwin-server.conf`
  - Check Nginx logs: `tail -f /var/log/nginx/error.log`
- **Playbook is idempotent:** You can safely re-run it multiple times.
- **For persistent issues:** Use the cleanup playbook to reset the environment.

---
For more help, see the comments in the playbooks or contact your administrator.

