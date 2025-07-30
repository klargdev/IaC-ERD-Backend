#!/usr/bin/env python3

import os
import sys
import json
import subprocess
import re
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse
import cgi
import threading
import time
import urllib.request

# Official download URLs
AGENT_DOWNLOADS = [
    {
        'name': 'OpenEDR Windows 64-bit',
        'filename': 'OpenEDR-Installation-2.5.1-Win64.msi',
        'url': 'https://github.com/openedr/openedr/releases/download/release-2.5.1/OpenEDR-Installation-2.5.1-Win64.msi'
    },
    {
        'name': 'OpenEDR Windows 32-bit',
        'filename': 'OpenEDR-Installation-2.5.1-Win32.msi',
        'url': 'https://github.com/openedr/openedr/releases/download/release-2.5.1/OpenEDR-Installation-2.5.1-Win32.msi'
    },
    {
        'name': 'Filebeat Windows',
        'filename': 'filebeat-8.11.0-windows-x86_64.zip',
        'url': 'https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.0-windows-x86_64.zip'
    },
    {
        'name': 'Logstash Windows',
        'filename': 'logstash-8.11.0-windows-x86_64.zip',
        'url': 'https://artifacts.elastic.co/downloads/logstash/logstash-8.11.0-windows-x86_64.zip'
    }
]

AGENTS_DIR = '/srv/btwin-server/agents'

class EDRGeneratorHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        form_data = parse_qs(post_data)
        btwin_url = form_data.get('url', ['http://localhost:8080'])[0]
        elasticsearch_url = form_data.get('elasticsearch', ['http://localhost:9200'])[0]

        # Step 1: Ensure all agent files are present
        download_status = []
        for agent in AGENT_DOWNLOADS:
            agent_path = os.path.join(AGENTS_DIR, agent['filename'])
            if not os.path.exists(agent_path):
                try:
                    download_status.append(f"Downloading {agent['name']}...")
                    urllib.request.urlretrieve(agent['url'], agent_path)
                    download_status.append(f"Downloaded {agent['name']}.")
                except Exception as e:
                    self.send_response(500)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    self.wfile.write(json.dumps({
                        'success': False,
                        'error': f"Failed to download {agent['name']}: {str(e)}",
                        'status': download_status
                    }).encode())
                    return
            else:
                download_status.append(f"{agent['name']} already present.")

        # Step 2: Generate the endpoint
        try:
            script_dir = '/srv/btwin-server/scripts'
            os.chdir(script_dir)
            result = subprocess.run(
                ['sudo', './edr-agent-generator.sh', btwin_url],
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode == 0:
                endpoint_id = None
                for line in result.stdout.split('\n'):
                    if 'Endpoint ID:' in line:
                        match = re.search(r'Endpoint ID:\s*([a-f0-9-]+)', line)
                        if match:
                            endpoint_id = match.group(1)
                            break
                if not endpoint_id:
                    import uuid
                    endpoint_id = str(uuid.uuid4())
                response = {
                    'success': True,
                    'endpoint_id': endpoint_id,
                    'message': 'Endpoint generated successfully',
                    'output': result.stdout,
                    'downloads': download_status,
                    'official_links': [
                        {'name': agent['name'], 'url': agent['url']} for agent in AGENT_DOWNLOADS
                    ]
                }
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
            else:
                response = {
                    'success': False,
                    'error': 'Failed to generate endpoint',
                    'stderr': result.stderr,
                    'stdout': result.stdout,
                    'downloads': download_status
                }
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
        except subprocess.TimeoutExpired:
            response = {
                'success': False,
                'error': 'Generation timed out',
                'downloads': download_status
            }
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        except Exception as e:
            response = {
                'success': False,
                'error': str(e),
                'downloads': download_status
            }
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
    
    def do_OPTIONS(self):
        # Handle CORS preflight requests
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

def run_server(port=8081):
    server_address = ('', port)
    httpd = HTTPServer(server_address, EDRGeneratorHandler)
    print(f"Starting EDR API server on port {port}")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server() 