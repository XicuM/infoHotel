import http.server
import socketserver
import sys
import os
import mimetypes
from backend.api_proxy import handle_proxy_get
from backend.api_storage import handle_write_json, handle_save_image, handle_delete_image
from backend.api_system import handle_open_terminal
from backend.flightradar_scraper import handle_flightradar_get

SKIP_HOTEL_ASSETS = os.environ.get('SKIP_HOTEL_ASSETS', '').lower() == 'true'

mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/pdf', '.pdf')
mimetypes.add_type('image/jpeg', '.jpg')
mimetypes.add_type('image/jpeg', '.jpeg')
mimetypes.add_type('image/png', '.png')
mimetypes.add_type('image/webp', '.webp')
mimetypes.add_type('image/gif', '.gif')
mimetypes.add_type('application/json', '.json')
mimetypes.add_type('font/woff', '.woff')
mimetypes.add_type('font/woff2', '.woff2')
mimetypes.add_type('font/ttf', '.ttf')
mimetypes.add_type('image/svg+xml', '.svg')

import gzip

def send_file_response(handler, file_path, content):
    accept_encoding = handler.headers.get('Accept-Encoding', '')
    ctype, _ = mimetypes.guess_type(file_path)
    
    use_gzip = 'gzip' in accept_encoding and (
        file_path.endswith('.js') or
        file_path.endswith('.json') or
        file_path.endswith('.wasm') or
        file_path.endswith('.html') or
        file_path.endswith('.css') or
        file_path.endswith('.svg')
    )
    
    if use_gzip:
        content = gzip.compress(content)
        
    handler.send_response(200)
    if ctype:
        handler.send_header('Content-Type', ctype)
    if use_gzip:
        handler.send_header('Content-Encoding', 'gzip')
    handler.send_header('Content-Length', str(len(content)))
    # HTML, JS, JSON, and bootstrap files MUST NOT be cached so code updates apply immediately
    if file_path.endswith('.json') or file_path.endswith('.html') or file_path.endswith('.js'):
        cache_header = 'no-cache, no-store, must-revalidate'
    else:
        cache_header = 'public, max-age=86400'
    handler.send_header('Cache-Control', cache_header)
    handler.end_headers()
    handler.wfile.write(content)

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
        if self.path.startswith('/api/openTerminal'):
            handle_open_terminal(self)
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
            
        import os
        from backend.config import BASE_DIR
        import urllib.parse
        
        path_without_query = self.path.split('?')[0]
        path_without_query = urllib.parse.unquote(path_without_query)
        clean_path = path_without_query.lstrip('/')
        if not clean_path:
            clean_path = 'index.html'

        serve_dir = sys.argv[2] if len(sys.argv) > 2 else '.'

        # 1. Try build/web directory first (compiled JS, canvaskit, AssetManifest, icons, flags, JSON data)
        target_file = os.path.join(serve_dir, clean_path)
        if os.path.isdir(target_file):
            target_file = os.path.join(target_file, 'index.html')

        if not (os.path.exists(target_file) and os.path.isfile(target_file)):
            alt_target = os.path.join(serve_dir, 'assets', clean_path)
            if os.path.exists(alt_target) and os.path.isfile(alt_target):
                target_file = alt_target

        if os.path.exists(target_file) and os.path.isfile(target_file):
            try:
                with open(target_file, 'rb') as f:
                    content = f.read()
                send_file_response(self, target_file, content)
                return
            except Exception as e:
                self.send_error(500, f"Error reading file: {e}")
                return

        # 2. Fallback to project root BASE_DIR (for heavy git-tracked hotel_assets)
        if SKIP_HOTEL_ASSETS and ('hotel_assets' in clean_path):
            self.send_response(403)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'SKIP_HOTEL_ASSETS is active')
            return

        if clean_path.startswith('assets/hotel_assets/'):
            git_path = clean_path[len('assets/'):]
        else:
            git_path = clean_path

        git_file = os.path.join(BASE_DIR, git_path)
        if os.path.exists(git_file) and os.path.isfile(git_file):
            try:
                with open(git_file, 'rb') as f:
                    content = f.read()
                send_file_response(self, git_file, content)
                return
            except Exception as e:
                self.send_error(500, f"Error reading file: {e}")
                return

        self.send_error(404, "File not found")

    def do_HEAD(self):
        self.do_GET()

    def log_message(self, fmt, *args):
        print(f"[server] {args[0]}", flush=True)

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    print(f"Starting modular backend server on port {port}...", flush=True)
    class ThreadingServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
        allow_reuse_address = True
        daemon_threads = True
    ThreadingServer(("", port), MainHandler).serve_forever()
