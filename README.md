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

### During Deployment - Password Setup
The playbook will pause during deployment to allow you to manually set the Elasticsearch password:

1. **The playbook will pause** and show you a command to run
2. **Open a new terminal** and run the displayed command:
   ```bash
   sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
   ```
3. **Enter a new password** when prompted by the command (you'll need to type it twice)
4. **Copy the generated password** and return to the Ansible terminal
5. **Enter the password** when Ansible prompts you (it will be hidden for security)
6. **Press Enter** to continue the deployment

This will:
- Install Java, Elasticsearch, Kibana, and TheHive
- Create all required directories and configuration files
- Set correct permissions
- Generate and configure self-signed TLS certificates
- Configure Kibana to connect to Elasticsearch with your chosen password
- Start all services and verify they are running

## Password Setup and Credentials
- The `elastic` user password is set manually during deployment for security
- The password you enter will be used for Kibana authentication with Elasticsearch
- The password is displayed at the end of the playbook for your reference
- To reset credentials, re-run the playbook and follow the manual password reset process again

## Resetting the Elasticsearch Password Manually
If you need to manually reset the password for the `elastic` user (or any built-in user), you can use the `elasticsearch-reset-password` tool. This can be helpful if you lose access or want to set a new password without redeploying.

**Usage:**
```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
```
- `-u` specifies the username (e.g., `-u elastic`).
- The command will prompt you to enter a new password interactively.

> **Note:** You can use any built-in username with the `-u` option, not just `elastic`.
> Run this command on the server where Elasticsearch is installed, with root or sudo privileges. You do not need to be in a specific directory, just provide the full path to the tool.

**After changing the password manually, you must also update Kibana's configuration:**
1. Edit `/etc/kibana/kibana.yml`
2. Update the `elasticsearch.password` field with your new password
3. Restart Kibana: `sudo systemctl restart kibana`

## Troubleshooting
- **If Elasticsearch fails to start:**
  - Run the cleanup playbook, then redeploy.
  - Check system requirements (RAM/CPU)
  - Review logs in `/var/log/elasticsearch/`
- **If Kibana cannot connect to Elasticsearch:**
  - Verify the password in `/etc/kibana/kibana.yml` matches the elastic user password
  - Restart Kibana: `sudo systemctl restart kibana`
  - Check Kibana logs: `sudo tail -f /var/log/kibana/kibana.log`
- **Playbook is idempotent:** You can safely re-run it multiple times.
- **For persistent issues:** Use the cleanup playbook to reset the environment.

## Accessing Services
- **Elasticsearch:** https://localhost:9200
- **Kibana:** https://localhost:5601
- **TheHive:** https://localhost:9000

---
For more help, see the comments in the playbooks or contact your administrator.

