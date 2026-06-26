#!/bin/bash

WEB_DIR="$HOME/infoHotel/build/web"
PORT=8080

if [ ! -d "$WEB_DIR" ]; then
    echo "Error: Flutter Web directory not found at $WEB_DIR"
    echo "Please transfer the build using the build_for_pi.sh script on your PC."
    exit 1
fi

echo "Starting micro-webserver on port $PORT..."
python3 -m http.server $PORT --directory "$WEB_DIR" > /dev/null 2>&1 &
SERVER_PID=$!

trap "kill $SERVER_PID" EXIT

echo "Initializing Cage + Cog Kiosk Display..."

# Configure Wayland/EGL environment variables using the current user ID
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export COG_PLATFORM_WL_VIEW_FULLSCREEN=1

# Enable remote Web Inspector for debugging (access at http://<pi-ip>:8081)
export WEBKIT_INSPECTOR_SERVER=0.0.0.0:8081

# Prevent wlroots/cage from crashing if no mouse or keyboard is plugged in
export WLR_LIBINPUT_NO_DEVICES=1

exec cage -d -- cog http://localhost:$PORT > /tmp/cage.log 2>&1
