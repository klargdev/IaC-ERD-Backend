# IaC-EDR-Backend

> **Note:**
> If you’re on a brand new Ubuntu system, you may need to install `git` first:
> ```sh
> sudo apt update && sudo apt install -y git
> ```

This repository provides an automated, reproducible Ansible-based deployment for an EDR (Elasticsearch, Kibana, TheHive) backend stack. It is designed for academic, research, and production use, following best practices for infrastructure as code (IaC).

---

> **Security:**
> Elasticsearch, Kibana, and TheHive are now secured with self-signed TLS/SSL certificates by default. You will access them via `https://` URLs. Your browser will warn you about the self-signed certificate; you can safely proceed or add the CA certificate to your trusted store for a better experience.

---

## ✨ Features
- **One-command deployment**: Run `./deploy.sh` to provision a full EDR backend stack.
- **Prerequisite checks**: Script verifies Python 3, Ansible, sshpass, and openssl are installed, and prints install instructions if not.
- **SSH key automation**: Prompts to generate and copy SSH keys for passwordless, secure automation.
- **Ansible Vault integration**: Sensitive variables are encrypted automatically.
- **User-friendly prompts**: Clear, step-by-step guidance for all required inputs.
- **Post-deployment health checks**: Script checks Kibana and TheHive endpoints and prints their status.
- **Security best practices**: Encourages SSH key use, vault secrets, and firewall rules.
- **Academic/professional documentation**: README and structure suitable for final year project submission.

---

## 🚦 Quick Start Guide (for ANYONE)

**1. (If needed) Install git**
```sh
sudo apt update && sudo apt install -y git
```

**2. Clone the repository**
```sh
git clone https://github.com/klargdev/IaC-ERD-Backend.git
cd IaC-EDR-Backend
```
> If you prefer SSH and have set up your GitHub SSH key, you can use:
> `git clone git@github.com:klargdev/IaC-ERD-Backend.git`

**3. Install prerequisites**
```sh
sudo apt install -y python3 python3-pip ansible sshpass openssl curl
```

**4. Make the deploy script executable**
```sh
chmod +x deploy.sh
```

**5. Run the magic!**
```sh
./deploy.sh
```

**6. Follow the prompts:**
- If you don’t have an SSH key, the script will help you create one (for remote deployments).
- **When asked for the target Ubuntu server IP:**
  - **If you are deploying on the same machine (local deployment):**
    - Enter `127.0.0.1` or `localhost` as the target IP.
    - SSH key and password prompts will be skipped, and Ansible will run locally.
  - **If you are deploying to a remote server:**
    - Enter the remote server's IP address.
    - The script will prompt for SSH username and password, and can copy your SSH key for passwordless access.
  - To find the IP, log in to your backend server and run:
    ```sh
    ip a
    # or
    hostname -I
    ```
  - Use the IP address shown (e.g., `192.168.1.100`).
  - If using a cloud server, use the public or private IP from your cloud dashboard.
- Sit back and watch as your EDR backend is provisioned and configured!

**7. When it’s done:**
- Access Kibana: `https://<your-server-ip>:5601`
- Access TheHive: `https://<your-server-ip>:9000`
- **Elasticsearch credentials will be printed at the end of the deployment!**
  - Username: `elastic`
  - Password: (see playbook output)
- Download the CA certificate from `/etc/elasticsearch/certs/ca.crt` if you want to trust it in your browser.

---

> **Security Note:**
> The default password for the `elastic` user is set in `group_vars/edr_backend.yml` as `elastic_password`. **Change this password for production deployments!**
> The password is printed at the end of the deployment for your convenience and is also used for Kibana to connect to Elasticsearch.

---

## 🪄 How it Works (Behind the Magic)
1. **Checks your system:** Ensures all required tools are installed.
2. **Handles SSH keys:** Generates and/or copies them for secure, passwordless automation.
3. **Initializes secrets:** Creates an Ansible Vault password for encrypting sensitive variables.
4. **Prompts for your backend server info:** IP, username, password.
5. **Writes inventory and variables:** Sets up Ansible’s inventory and group variables for your environment.
6. **Encrypts secrets:** Uses Ansible Vault to protect sensitive data.
7. **Runs the Ansible playbook:** Provisions and configures Elasticsearch, Kibana, and TheHive on your backend server.
8. **Checks service health:** Verifies Kibana and TheHive are up and running.
9. **Prints access info:** Tells you where to find your dashboards and credentials.

---

## 🛠️ Troubleshooting & FAQ

**Q: The script says a package is missing!**
- A: Copy the install command it prints and run it, then re-run `./deploy.sh`.

**Q: SSH key copy fails or asks for password every time.**
- A: Make sure the backend server allows SSH from your control node. Try copying the key manually:
  ```sh
  ssh-copy-id -i ~/.ssh/id_ed25519.pub <user>@<backend-ip>
  ```

**Q: Playbook fails with permission errors.**
- A: Ensure your backend user has sudo privileges.

**Q: Kibana or TheHive health check says [WARN].**
- A: Wait a minute and try again, or check the backend server logs for errors.

**Q: Health checks say curl not found!**
- A: Install curl with: sudo apt install -y curl

**Q: How do I reset/redeploy?**
- A: You can re-run `./deploy.sh` as many times as you like. It will overwrite inventory and variables as needed.

**Q: Can I customize versions or settings?**
- A: Edit `group_vars/edr_backend.yml` before running the script, or after (then re-encrypt with Ansible Vault).

**Q: Is it safe to commit my secrets?**
- A: Never commit `vault/.vault_pass` or any real secrets. The repo’s `.gitignore` helps protect you.

---

## 🖥️ Sample Output
```
[OK] All prerequisites are installed.
[INFO] No SSH key found in ~/.ssh.
Generate a new SSH key pair for Ansible control node? [Y/n]: Y
[OK] SSH key generated.
[STEP] Initializing Ansible Vault...
[OK] Vault password created at vault/.vault_pass.
Enter target Ubuntu server IP: 192.168.1.100
Enter SSH username [ubuntu]: ubuntu
Enter SSH password: 
Copy SSH public key to backend server for passwordless access? [Y/n]: Y
[OK] SSH key copied.
[STEP] Writing inventory/hosts.yml...
[STEP] Writing group_vars/edr_backend.yml...
[STEP] Starting deployment...
PLAY [Deploy EDR Backend Stack] ...
...
TASK [elasticsearch : Print Elasticsearch credentials] *********************************
  msg:
    Elasticsearch is ready!
    Username: elastic
    Password: ChangeMe-EDR-2024!
...
[STEP] Post-deployment health checks...
Checking Kibana at http://192.168.1.100:5601 ... [UP]
Checking TheHive at http://192.168.1.100:9000 ... [UP]
(Elasticsearch is usually not HTTP-browsable, check with: curl -sk http://192.168.1.100:9200)

✅ EDR Backend Successfully Deployed!
🔗 Kibana Dashboard: https://192.168.1.100:5601
🔗 TheHive Console: https://192.168.1.100:9000
ℹ️ Elastic credentials: Username: elastic, Password: ChangeMe-EDR-2024!
```

---

## 📚 Academic Implementation Requirements

This project was designed to meet the following baseline requirements for an Ansible control node and EDR backend provisioning:

### 3.3.1 Ansible Control Node Requirements

1. **Operating System:**
   - Ubuntu Server LTS (22.04) is recommended for the control node for stability and support.
2. **Required Packages:**
   - The control node should have Python 3, pip, ansible, sshpass, and openssl installed to enable secure SSH, encrypted variable management, and role-based execution.
3. **Network and Connectivity:**
   - SSH key pairs should be generated and securely stored on the control node for passwordless, encrypted SSH connections to the backend server. Keys are distributed only to the backend server at this stage.
4. **Backend Server Provisioning:**
   - The backend EDR server should be deployed in an isolated lab environment with a static private IP. Firewall rules should restrict SSH access to only the control node’s IP.
5. **Privileges and Security:**
   - The backend server must accept SSH connections with sudo privileges, allowing Ansible to perform privileged tasks (e.g., package installation, upgrades, configuration changes).
6. **Sensitive Data Management:**
   - Ansible Vault is used to encrypt sensitive variables, SSH keys, and API tokens. TLS/SSL certificates are included in roles to secure Elasticsearch and Kibana communications (HTTPS enforced).
7. **Playbook Structure:**
   - The project uses a master playbook (`site.yml`) and modular roles:
     - `roles/elasticsearch`: Elasticsearch install, GPG key, repo, systemd, TLS certs
     - `roles/kibana`: Kibana install, config, reverse proxy (if needed), HTTPS
     - `roles/thehive`: TheHive deploy, config, DB init, web interface test
8. **Version Control and Reproducibility:**
   - All playbooks, inventory, and encrypted variable files are version-controlled for traceability and reproducibility.

---

## 🗂️ Repository Structure

```
IaC-EDR-Backend/
├── inventory/       # Inventory files listing your backend servers and groups
├── group_vars/      # Group-specific variables (e.g., passwords, tokens)
├── roles/           # Ansible roles (e.g., elasticsearch, kibana, thehive)
├── site.yml         # Master playbook that ties all roles together
├── ansible.cfg      # Ansible configuration file
├── README.md        # This project description
├── .gitignore       # Ignore files (e.g., secrets, local configs)
└── vault/           # (Optional) Encrypted secrets storage (DO NOT commit vault passwords!)
```

---

## ⚠️ Security Notes
- **Never commit `vault/.vault_pass` or any real secrets to version control.**
- The vault password is generated per run and stored locally for Ansible Vault operations.
- Use SSH keys for secure, passwordless access between control node and backend server.
- Restrict backend server SSH access to only the control node’s IP via firewall rules.

## 📝 Customization
- Edit `group_vars/edr_backend.yml` before running the script, or after (then re-encrypt with Ansible Vault).
- Extend roles in `roles/` to add handlers, templates, or additional configuration as needed.
- Add your own TLS/SSL certificates to the appropriate roles for HTTPS enforcement.

## 📋 Requirements
- Ansible must be installed on the machine running `deploy.sh`.
- Target server(s) must be Ubuntu-based and accessible via SSH.
- SSH key-based authentication is strongly recommended for security and automation.

---

**Happy automating!**

