# EDR Backend Stack Deployment (Ansible)

## System Requirements
- **Minimum:** 2GB RAM, 2 CPUs
- **OS:** Ubuntu (tested on 20.04/22.04)
- **Ansible:** v2.10+

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
2. Deploy the full EDR backend stack:

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

## Security and Authentication

**Authentication between Kibana and Elasticsearch is now disabled.**
- No password is required for accessing Elasticsearch or Kibana.
- Kibana connects to Elasticsearch without authentication.
- This setup is intended for local development or testing only.

> **WARNING:**
> This configuration disables all security and authentication for Elasticsearch and Kibana.
> Anyone who can access your server can access all data and services without restriction.
> **Do not use this configuration in production!**

## Troubleshooting
- **If Elasticsearch, Kibana, or TheHive fails to start:**
  - Run the cleanup playbook, then redeploy.
  - Check system requirements (RAM/CPU)
  - Review logs in `/var/log/elasticsearch/`, `/var/log/kibana/`, or `/var/log/thehive/`
- **Playbook is idempotent:** You can safely re-run it multiple times.
- **For persistent issues:** Use the cleanup playbook to reset the environment.

## Accessing Services
- **Elasticsearch:** https://localhost:9200
- **Kibana:** https://localhost:5601
- **TheHive:** https://localhost:9000

---
For more help, see the comments in the playbooks or contact your administrator.

