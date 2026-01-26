import http.server
import socketserver
import json
import csv
import os

PORT = 8000
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VACCINES_FILE = os.path.join(BASE_DIR, 'vaccines.json')
CLINICS_FILE = os.path.join(BASE_DIR, 'clinics.csv')

class JSONRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/vaccines':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            try:
                with open(VACCINES_FILE, 'rb') as file:
                    self.wfile.write(file.read())
            except Exception:
                self.send_error(500, "Error reading vaccines file")
        
        elif self.path == '/emergency-clinics':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            clinics = []
            try:
                with open(CLINICS_FILE, 'r', encoding='utf-8') as file:
                    reader = csv.DictReader(file)
                    for row in reader:
                        if row.get('emergency_24h', '').strip().upper() == 'TRUE':
                            clinics.append(row)
                
                self.wfile.write(json.dumps(clinics).encode('utf-8'))
            except Exception as e:
                 print(f"Error reading clinics CSV: {e}")
                 self.wfile.write(json.dumps([]).encode('utf-8'))

        elif self.path == '/clinics':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            clinics = []
            try:
                with open(CLINICS_FILE, 'r', encoding='utf-8') as file:
                    reader = csv.DictReader(file)
                    for row in reader:
                        clinics.append(row)
                
                self.wfile.write(json.dumps(clinics).encode('utf-8'))
            except Exception as e:
                 print(f"Error reading clinics CSV: {e}")
                 self.wfile.write(json.dumps([]).encode('utf-8'))

        else:
            self.send_error(404, "Not Found")

# Change directory to script location to ensure it finds the json file
script_dir = os.path.dirname(os.path.realpath(__file__))
os.chdir(script_dir)

print(f"Serving at http://localhost:{PORT}")
with socketserver.TCPServer(("", PORT), JSONRequestHandler) as httpd:
    httpd.serve_forever()
