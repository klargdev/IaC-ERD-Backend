# BTWIN-SERVER (Betweener Server)

This server acts as a webserver and relay for onboarding endpoints (Linux, Windows, Mac) with your EDR stack.

## Purpose
- Hosts the full agent install scripts for each OS (Linux, Windows, Mac)
- Hosts the tiny bootstrapper scripts for each OS
- Receives "call home" requests from endpoints
- Optionally logs or registers new endpoints
- Forwards telemetry to the main Elastic Stack (Elasticsearch, Kibana, TheHive)

## Usage
- Place your OS-specific install scripts in the `scripts/` directory
- Place your tiny bootstrapper scripts in the `bootstrap/` directory
- Serve these directories via a webserver (Flask, Nginx, Apache, etc.)
- Distribute the one-liner bootstrapper commands to endpoint users/admins

## Example Directory Structure

```
BTWIN-SERVER/
  bootstrap/           # Tiny one-liner scripts for each OS
  scripts/             # Full install scripts for each OS
  logs/                # (Optional) Endpoint registration logs
  README.md
  ... (webserver code/config)
```

## Security
- Restrict access to the scripts as needed
- Optionally require endpoint registration/approval
- Do not expose sensitive data in scripts

---
For more details, see the EDR_AGENT project and your main IaC-EDR-Backend stack. 