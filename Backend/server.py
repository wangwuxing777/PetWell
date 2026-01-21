import http.server
import socketserver
import json
import os

PORT = 8000
JSON_FILE = 'vaccines.json'

class JSONRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/vaccines':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            with open(JSON_FILE, 'rb') as file:
                self.wfile.write(file.read())
        else:
            self.send_error(404, "Not Found")

# Change directory to script location to ensure it finds the json file
script_dir = os.path.dirname(os.path.realpath(__file__))
os.chdir(script_dir)

print(f"Serving at http://localhost:{PORT}")
with socketserver.TCPServer(("", PORT), JSONRequestHandler) as httpd:
    httpd.serve_forever()
