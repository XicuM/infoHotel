#!/bin/bash
exec >&2

WEB_DIR="$HOME/infoHotel/build/web"
PORT=8080

if [ ! -d "$WEB_DIR" ]; then
    echo "Error: Flutter Web directory not found at $WEB_DIR"
    echo "Please transfer the build using the build_for_pi.sh script on your PC."
    exit 1
fi

echo "Starting micro-webserver on port $PORT..."
cat << 'PYEOF' > "$HOME/infoHotel/scripts/serve.py"
import http.server, socketserver, mimetypes, sys, urllib.request, urllib.parse, urllib.error, json

mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/javascript', '.js')

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=sys.argv[1], **kwargs)

    def do_GET(self):
        if self.path.startswith('/api/proxy'):
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            target_url = params.get('url', [None])[0]
            if not target_url:
                self.send_error(400, "Missing 'url' parameter")
                return
            
            headers = {}
            for name, value in self.headers.items():
                if name.lower() in ['api_key', 'x-rapidapi-key', 'x-rapidapi-host']:
                    headers[name] = value
            
            try:
                req = urllib.request.Request(target_url, headers=headers)
                with urllib.request.urlopen(req, timeout=10) as response:
                    res_body = response.read()
                    content_type = response.headers.get('Content-Type', 'application/json')
                
                self.send_response(200)
                self.send_header('Content-Type', content_type)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(res_body)
                return
            except urllib.error.HTTPError as e:
                self.send_response(e.code)
                self.send_header('Content-Type', 'text/plain')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                try:
                    self.wfile.write(e.read())
                except:
                    pass
                return
            except Exception as e:
                self.send_error(500, f"Proxy error: {str(e)}")
                return
        
        super().do_GET()

socketserver.TCPServer(("", int(sys.argv[2])), Handler).serve_forever()
PYEOF

python3 "$HOME/infoHotel/scripts/serve.py" "$WEB_DIR" $PORT > /dev/null 2>&1 &

echo "Initializing Cage + Cog Kiosk Display..."

# Configure Wayland/EGL environment variables using the current user ID
export XDG_RUNTIME_DIR=/run/user/$(id -u)
# Clean up any stale Wayland socket from a previous run to ensure the wait loop triggers correctly
rm -f "$XDG_RUNTIME_DIR/wayland-0" "$XDG_RUNTIME_DIR/wayland-0.lock"
export COG_PLATFORM_WL_VIEW_FULLSCREEN=1

# Enable remote Web Inspector for debugging (access at http://<pi-ip>:8081)
export WEBKIT_INSPECTOR_SERVER=0.0.0.0:8081

# Prevent wlroots/cage from crashing if no mouse or keyboard is plugged in
export WLR_LIBINPUT_NO_DEVICES=1

# Disable the WebKit sandbox to fix the 'bwrap' / 'dbus-proxy' crash on Raspbian
export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1
export WPE_DISABLE_SANDBOX=1

# Force WebGL and ignore GPU blacklists which often block the Pi 3B+
export WEBKIT_IGNORE_GPU_BLACKLIST=1
export WEBKIT_FORCE_COMPOSITING_MODE=1
export COG_USE_WEBGL=1
export WPE_DRM_DEVICE=/dev/dri/card0
export WPE_DRM_RENDER_NODE=/dev/dri/renderD128

# Execute cage as the main process, allowing logs to flow directly to systemd journal
# You can set the COG_SCALE environment variable (e.g. export COG_SCALE=1.25) to scale the UI.
# You can set the KIO_RES environment variable (e.g. export KIO_RES=1280x720) to change the display resolution.

if [ -n "$KIO_RES" ]; then
    (
        # Wait for the Wayland compositor socket to be initialized
        while [ ! -S "$XDG_RUNTIME_DIR/wayland-0" ]; do
            sleep 0.5
        done
        export WAYLAND_DISPLAY=wayland-0
        
        # Wait for outputs to populate in wlroots
        sleep 2
        
        echo "=== Display diagnostic logs ==="
        wlr-randr || echo "wlr-randr failed to run!"
        echo "==============================="
        
        # Find the active display connector name (e.g. HDMI-A-1 or DSI-1)
        CONNECTOR=$(wlr-randr | grep -m1 '^[A-Za-z0-9-]' | awk '{print $1}')
        
        if [ -n "$CONNECTOR" ]; then
            echo "Applying resolution ${KIO_RES} to output ${CONNECTOR}..."
            wlr-randr --output "$CONNECTOR" --mode "${KIO_RES}@60.000000Hz" || \
            wlr-randr --output "$CONNECTOR" --mode "${KIO_RES}@60Hz" || \
            wlr-randr --output "$CONNECTOR" --mode "${KIO_RES}" || \
            echo "Failed to set resolution with wlr-randr"
        fi
    ) 2>&1 &
fi

cage -d -- cog --platform=fdo --scale="${COG_SCALE:-1.0}" http://localhost:$PORT
