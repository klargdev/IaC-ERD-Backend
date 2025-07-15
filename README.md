# IaC-ERD-Backend
Ansible IaC for deploying a free open-source EDR backend stack (Elasticsearch, Kibana, TheHive). Automates secure setup for small orgs, startups, or research to boost threat detection and incident response with zero enterprise licensing costs.

# IaC-EDR-Backend

This repository provides a ready-to-use **Infrastructure as Code (IaC)** setup for deploying an **Endpoint Detection and Response (EDR) backend** using open-source tools.  
It uses **Ansible** to automate the provisioning and configuration of:

- **Elasticsearch** (centralized security telemetry storage)
- **Kibana** (visualization and threat dashboard)
- **TheHive** (incident response and case management)

---

## 📌 **Project Goals**

- Enable small teams to deploy a full EDR backend with **zero license costs**.
- Automate backend provisioning with Ansible for repeatability and auditability.
- Provide an example structure for academic research and production pilots.

---

## 🗂️ **Repository Structure**
```plaintext
IaC-EDR-Backend/
├── inventory/       # Inventory files listing your backend servers and groups
├── group_vars/      # Group-specific variables (e.g., passwords, tokens)
├── roles/           # Ansible roles (e.g., elasticsearch, kibana, thehive)
├── site.yml         # Master playbook that ties all roles together
├── ansible.cfg      # Ansible configuration file
├── README.md        # This project description
├── .gitignore       # Ignore files (e.g., secrets, local configs)
└── vault/           # (Optional) Encrypted secrets storage (DO NOT commit vault passwords!)

Explanation:

inventory/ — Defines your target backend server(s) and host groups.

group_vars/ — Stores variables for different host groups (credentials, ports, etc.).

roles/ — Contains modular tasks for Elasticsearch, Kibana, and TheHive setup.

site.yml — Main playbook — runs all roles in order for complete EDR backend provisioning.

ansible.cfg — Ansible’s config file (e.g., SSH settings, default paths).

vault/ — Folder for sensitive secrets encrypted with Ansible Vault — never push your vault keys.

```

## 🚀 **Quick Start**

1. **Clone this repository**

   ```bash
   git clone https://github.com/klargdev/IaC-EDR-Backend.git
   cd IaC-EDR-Backend

   Configure your inventory

Add your backend server(s) to inventory/hosts.yml.

Set your variables

Edit group_vars/ and encrypt secrets with ansible-vault.

Run the playbook

ansible-playbook -i inventory/hosts.yml site.yml
```
##🛡️ Security Note
🚫 Never commit real SSH keys, vault passwords, or API tokens.
Use .gitignore and Ansible Vault to protect sensitive data.

##📖 License
This project is licensed under the MIT License.
Feel free to fork and adapt it for your own EDR projects!


##✏️ Author
Maintained by Lartey Kpabitey Gabriel.
Part of a practical case study for a secure, automated EDR deployment.

