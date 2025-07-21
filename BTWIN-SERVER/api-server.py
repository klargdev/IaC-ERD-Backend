#!/usr/bin/env python3

import os
import sys
import json
import subprocess
import re
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse
import cgi

class EDRGeneratorHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        # Parse the request
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        # Parse form data
        form_data = parse_qs(post_data)
        
        # Extract parameters
        btwin_url = form_data.get('url', ['http://localhost:8080'])[0]
        elasticsearch_url = form_data.get('elasticsearch', ['http://localhost:9200'])[0]
        
        try:
            # Change to the scripts directory
            script_dir = '/srv/btwin-server/scripts'
            os.chdir(script_dir)
            
            # Run the EDR agent generator
            result = subprocess.run(
                ['sudo', './edr-agent-generator.sh', btwin_url],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                # Extract endpoint ID from output
                endpoint_id = None
                for line in result.stdout.split('\n'):
                    if 'Endpoint ID:' in line:
                        match = re.search(r'Endpoint ID:\s*([a-f0-9-]+)', line)
                        if match:
                            endpoint_id = match.group(1)
                            break
                
                if not endpoint_id:
                    # Generate a fallback endpoint ID
                    import uuid
                    endpoint_id = str(uuid.uuid4())
                
                # Return success response
                response = {
                    'success': True,
                    'endpoint_id': endpoint_id,
                    'message': 'Endpoint generated successfully',
                    'output': result.stdout
                }
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
                
            else:
                # Return error response
                response = {
                    'success': False,
                    'error': 'Failed to generate endpoint',
                    'stderr': result.stderr,
                    'stdout': result.stdout
                }
                
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
                
        except subprocess.TimeoutExpired:
            response = {
                'success': False,
                'error': 'Generation timed out'
            }
            
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
            
        except Exception as e:
            response = {
                'success': False,
                'error': str(e)
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