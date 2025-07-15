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

IaC-EDR-Backend/
├── inventory/ # Inventory hosts files
├── group_vars/ # Group-specific variables
├── roles/ # Ansible roles: elasticsearch, kibana, thehive
├── site.yml # Master playbook to run all roles
├── ansible.cfg # Ansible configuration
├── README.md # This file
├── .gitignore # Ignore secrets, local configs, etc.
└── vault/ # (Optional) Encrypted secrets (do not push your vault passwords!)


---

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

🛡️ Security Note
🚫 Never commit real SSH keys, vault passwords, or API tokens.
Use .gitignore and Ansible Vault to protect sensitive data.

📖 License
This project is licensed under the MIT License.
Feel free to fork and adapt it for your own EDR projects!


✏️ Author
Maintained by Lartey Kpabitey Gabriel.
Part of a practical case study for a secure, automated EDR deployment.

