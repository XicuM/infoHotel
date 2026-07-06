import http.server
import socketserver
import sys
import mimetypes
from backend.api_proxy import handle_proxy_get
from backend.api_storage import handle_write_json, handle_save_image, handle_delete_image
from backend.flightradar_scraper import handle_flightradar_get

mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/javascript', '.js')

class MainHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # Serve the web directory if passed as second argument, else current directory
        serve_dir = sys.argv[2] if len(sys.argv) > 2 else '.'
        super().__init__(*args, directory=serve_dir, **kwargs)

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, *')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_POST(self):
        if self.path.startswith('/api/writeJson'):
            handle_write_json(self)
            return
        if self.path.startswith('/api/saveImage'):
            handle_save_image(self)
            return
        if self.path.startswith('/api/deleteImage'):
            handle_delete_image(self)
            return
        self.send_error(404, "Not found")

    def do_GET(self):
        if self.path.startswith('/api/proxy'):
            handle_proxy_get(self)
            return
        if self.path.startswith('/api/flights'):
            handle_flightradar_get(self)
            return
        
        # If it's an API route but not proxy, return 404
        if self.path.startswith('/api/'):
            self.send_error(404, "Not found")
            return
            
        # Intercept requests for dynamic assets/data to serve from project root
        import os
        from backend.config import BASE_DIR
        
        # Remove query params (like ?cb=1234) for file path resolution
        path_without_query = self.path.split('?')[0]
        
        if path_without_query.startswith('/hotel_assets/'):
            # Strip the leading slash to make it relative to BASE_DIR
            relative_path = path_without_query.lstrip('/')
            file_path = os.path.join(BASE_DIR, relative_path)
            
            if os.path.exists(file_path) and os.path.isfile(file_path):
                try:
                    with open(file_path, 'rb') as f:
                        content = f.read()
                    self.send_response(200)
                    # Guess MIME type
                    ctype, _ = mimetypes.guess_type(file_path)
                    if ctype:
                        self.send_header('Content-Type', ctype)
                    self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
                    self.end_headers()
                    self.wfile.write(content)
                    return
                except Exception as e:
                    self.send_error(500, f"Error reading file: {e}")
                    return
            
        super().do_GET()

    def log_message(self, fmt, *args):
        print(f"[server] {args[0]}", flush=True)

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    print(f"Starting modular backend server on port {port}...", flush=True)
    class ThreadingServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
        allow_reuse_address = True
        daemon_threads = True
    ThreadingServer(("", port), MainHandler).serve_forever()
