#!/bin/bash

WEB_DIR="$HOME/infoHotel/build/web"
PORT=8080

if [ ! -d "$WEB_DIR" ]; then
    echo "Error: Flutter Web directory not found at $WEB_DIR"
    echo "Please transfer the build using the build_for_pi.sh script on your PC."
    exit 1
fi

echo "Starting micro-webserver on port $PORT..."
cat << 'PYEOF' > "$HOME/infoHotel/scripts/serve.py"
import http.server, socketserver, mimetypes, sys
mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/javascript', '.js')
class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=sys.argv[1], **kwargs)
socketserver.TCPServer(("", int(sys.argv[2])), Handler).serve_forever()
PYEOF

python3 "$HOME/infoHotel/scripts/serve.py" "$WEB_DIR" $PORT > /dev/null 2>&1 &

echo "Initializing Cage + Cog Kiosk Display..."

# Configure Wayland/EGL environment variables using the current user ID
export XDG_RUNTIME_DIR=/run/user/$(id -u)
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

# Execute cage as the main process, allowing logs to flow directly to systemd journal
# You can set the COG_SCALE environment variable (e.g. export COG_SCALE=1.25) to scale the UI (simulate smaller resolution).
# Defaults to 1.0 if not specified.
exec cage -d -- cog --scale="${COG_SCALE:-1.0}" http://localhost:$PORT
