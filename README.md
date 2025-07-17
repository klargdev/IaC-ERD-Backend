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

**Note:** When prompted for BECOME password", enter your **sudo password** (the same password you use when running `sudo` commands).

This will:
- Stop Elasticsearch if running
- Remove Elasticsearch packages, data, logs, and configuration
- Remove the Elastic GPG key and repository
- Leave your system ready for a clean redeployment

## Deployment Instructions
1. **(Optional but recommended)** Run the cleanup playbook above if you have a failed or partial install.
2. Deploy the full EDR backend stack:

```bash
ansible-playbook -i inventory/hosts site.yml --ask-become-pass
```

**Note:** When prompted for BECOME password", enter your **sudo password** (the same password you use when running `sudo` commands).

This will:
- Install Java, Elasticsearch, Kibana, and TheHive
- Create all required directories and configuration files
- Set correct permissions
- Generate and configure self-signed TLS certificates
- Set up secure passwords and print/save credentials
- Start all services and verify they are running

## Password Setup and Credentials
- Passwords for Elasticsearch and Kibana are set automatically on first deploy.
- Credentials are printed at the end of the playbook and saved to `/etc/elasticsearch/edr-credentials.txt`.
- To reset credentials, re-run the playbook or use the provided script.

## Troubleshooting
- **If Elasticsearch fails to start:**
  - Run the cleanup playbook, then redeploy.
  - Check system requirements (RAM/CPU)
  - Review logs in `/var/log/elasticsearch/`
- **Playbook is idempotent:** You can safely re-run it multiple times.
- **For persistent issues:** Use the cleanup playbook to reset the environment.

## Accessing Services
- **Elasticsearch:** https://localhost:9200
- **Kibana:** https://localhost:5601
- **TheHive:** https://localhost:9000

---
For more help, see the comments in the playbooks or contact your administrator.

